# frozen_string_literal: true

require_relative 'test_helper'
require 'agent_workflows/merge'

module MergeFixtures
  HEAD = 'a' * 40

  class Client
    attr_accessor :snapshots, :checks, :review_result, :mutation_result, :mutation_error
    attr_reader :mutations, :requested_review

    def initialize
      @mutations = []
    end

    def snapshot
      value = snapshots.length > 1 ? snapshots.shift : snapshots.first
      raise value if value.is_a?(Exception)

      value
    end

    def required_checks
      raise checks if checks.is_a?(Exception)

      checks
    end

    def review(id)
      @requested_review = id
      raise review_result if review_result.is_a?(Exception)

      review_result
    end

    def graphql(query, variables)
      @mutations << [query, variables]
      raise mutation_error if mutation_error

      mutation_result
    end
  end

  def setup
    @client = Client.new
    @client.snapshots = [snapshot]
    @client.checks = [{ 'name' => 'Validate', 'state' => 'SUCCESS', 'bucket' => 'pass' }]
    @client.review_result = { 'id' => 17, 'commit_id' => HEAD, 'state' => 'COMMENTED', 'body' => 'Walkthrough' }
    @client.mutation_result = { 'mergePullRequest' => { 'pullRequest' => {
      'headRefOid' => HEAD, 'state' => 'MERGED', 'merged' => true, 'mergeCommit' => { 'oid' => 'b' * 40 }
    } } }
    @merge = AgentWorkflows::Merge.new(@client)
  end

  def snapshot
    { 'id' => 'PR_123', 'headRefOid' => HEAD, 'state' => 'OPEN', 'isDraft' => false,
      'viewerCanMergeAsAdmin' => false, 'isMergeQueueEnabled' => false, 'isInMergeQueue' => false,
      'autoMergeRequest' => nil, 'mergeStateStatus' => 'CLEAN', 'reviewDecision' => nil }
  end

  def assert_blocked(pattern)
    error = assert_raises(AgentWorkflows::Error) { @merge.call(head: HEAD, walkthrough: 17) }
    assert_match pattern, error.message
    assert_empty @client.mutations
  end
end

class MergeNativeGateTest < Minitest::Test
  include MergeFixtures

  def test_refuses_a_draft_or_closed_pull_request
    [{ 'isDraft' => true }, { 'state' => 'CLOSED' }].each do |changes|
      @client.snapshots = [snapshot.merge(changes)]
      assert_blocked(/open and not a draft/)
    end
  end

  def test_refuses_stale_or_unknown_merge_state
    %w[BEHIND BLOCKED DIRTY DRAFT HAS_HOOKS UNKNOWN UNSTABLE].each do |state|
      @client.snapshots = [snapshot.merge('mergeStateStatus' => state)]
      assert_blocked(/not CLEAN/)
    end
  end

  def test_refuses_bypass_capable_or_unknown_actor
    [true, nil].each do |value|
      @client.snapshots = [snapshot.merge('viewerCanMergeAsAdmin' => value)]
      assert_blocked(/protection must be enforced/)
    end
  end

  def test_refuses_queue_requirement_even_before_enqueue
    %w[isMergeQueueEnabled isInMergeQueue].each do |key|
      [true, nil].each do |value|
        @client.snapshots = [snapshot.merge(key => value)]
        assert_blocked(/queues are unsupported/)
      end
    end
  end

  def test_refuses_existing_or_unknown_delayed_auto_merge
    @client.snapshots = [snapshot.merge('autoMergeRequest' => { 'enabledAt' => '2026-09-14T00:00:00Z' })]
    assert_blocked(/delayed auto-merge/)
    @client.snapshots = [snapshot.except('autoMergeRequest')]
    assert_blocked(/delayed auto-merge/)
  end

  def test_missing_required_approval_or_changes_requested_blocks
    %w[REVIEW_REQUIRED CHANGES_REQUESTED FUTURE_STATE].each do |state|
      @client.snapshots = [snapshot.merge('reviewDecision' => state)]
      assert_blocked(/Required reviews/)
    end
    @client.snapshots = [snapshot.except('reviewDecision')]
    assert_blocked(/Required reviews/)
  end
end

class MergeCheckTest < Minitest::Test
  include MergeFixtures

  def test_accepts_github_terminal_check_conclusions
    @client.checks = [%w[SUCCESS pass], %w[NEUTRAL skipping], %w[SKIPPED skipping]].map do |state, bucket|
      { 'name' => state, 'state' => state, 'bucket' => bucket }
    end
    assert_equal 'MERGED', @merge.call(head: HEAD, walkthrough: 17)['state']
  end

  def test_empty_or_unknown_check_list_blocks
    [[], nil, {}].each do |checks|
      @client.checks = checks
      assert_blocked(/No observable required checks/)
    end
  end

  def test_failed_pending_cancelled_or_unknown_checks_block
    %w[FAILURE ERROR PENDING IN_PROGRESS CANCELLED TIMED_OUT EXPECTED FUTURE_STATE].each do |state|
      @client.checks = [{ 'name' => 'Validate', 'state' => state, 'bucket' => 'pass' }]
      assert_blocked(/Required check/)
    end
  end

  def test_inconsistent_or_malformed_check_results_block
    [nil, 'success', {}, { 'state' => 'SUCCESS', 'bucket' => 'pass' },
     { 'name' => 'Validate', 'state' => 'SUCCESS', 'bucket' => 'pending' },
     { 'name' => 'Validate', 'state' => 'SKIPPED', 'bucket' => 'pass' }].each do |check|
      @client.checks = [check]
      assert_blocked(/Required check/)
    end
  end

  def test_api_failure_does_not_submit
    @client.checks = AgentWorkflows::Error.new('GitHub unavailable')
    assert_blocked(/GitHub unavailable/)
  end
end

class MergeWalkthroughTest < Minitest::Test
  include MergeFixtures

  def test_wrong_review_id_or_head_blocks
    [{ 'id' => 99 }, { 'commit_id' => 'c' * 40 }].each do |changes|
      @client.review_result = { 'id' => 17, 'commit_id' => HEAD }.merge(changes)
      assert_blocked(/review on this PR at the expected head/)
    end
  end

  def test_missing_review_on_this_pull_request_blocks
    @client.review_result = AgentWorkflows::Error.new('Review not found on this PR')
    assert_blocked(/not found on this PR/)
  end

  def test_pending_approving_or_blank_reviews_do_not_count_as_walkthroughs
    [{ 'state' => 'PENDING' }, { 'state' => 'APPROVED' }, { 'body' => '  ' }, { 'body' => nil }].each do |changes|
      @client.review_result = { 'id' => 17, 'commit_id' => HEAD, 'state' => 'COMMENTED',
                                'body' => 'Tour' }.merge(changes)
      assert_blocked(/submitted COMMENT review/)
    end
  end
end

class MergeSubmissionTest < Minitest::Test
  include MergeFixtures

  def test_rejects_invalid_head_before_submission
    [nil, '', 'main'].each do |head|
      error = assert_raises(AgentWorkflows::Error) { @merge.call(head: head, walkthrough: 17) }
      assert_match(/full commit SHA/, error.message)
    end
    assert_empty @client.mutations
  end

  def test_initial_stale_head_or_missing_identity_blocks
    @client.snapshots = [snapshot.merge('headRefOid' => 'c' * 40)]
    assert_blocked(/PR head changed/)
    @client.snapshots = [snapshot.except('id')]
    assert_blocked(/identity is missing/)
  end

  def test_passes_expected_head_to_server_and_returns_native_merge_result
    @client.snapshots = [snapshot.merge('reviewDecision' => 'APPROVED')]
    result = @merge.call(head: HEAD, walkthrough: 17)
    assert_equal 'b' * 40, result.dig('mergeCommit', 'oid')
    assert_equal 17, @client.requested_review
    query, variables = @client.mutations.fetch(0)
    assert_includes query, 'expectedHeadOid: $head'
    assert_equal({ 'id' => 'PR_123', 'head' => HEAD }, variables)
    assert_equal 1, @client.mutations.length
  end

  def test_changed_head_after_reading_checks_blocks
    @client.snapshots = [snapshot, snapshot.merge('headRefOid' => 'c' * 40)]
    assert_blocked(/PR head changed/)
  end

  def test_changed_gate_after_reading_checks_blocks
    @client.snapshots = [snapshot, snapshot.merge('reviewDecision' => 'CHANGES_REQUESTED')]
    assert_blocked(/Required reviews/)
  end

  def test_head_change_at_server_is_rejected_without_retry
    @client.mutation_error = AgentWorkflows::Error.new('Head branch was modified')
    error = assert_raises(AgentWorkflows::Error) { @merge.call(head: HEAD, walkthrough: 17) }
    assert_match(/Head branch was modified.*inspect live PR state/, error.message)
    assert_equal 1, @client.mutations.length
  end

  def test_unknown_mutation_outcome_requires_inspection
    [nil, 'merged', { 'pullRequest' => { 'state' => 'MERGED' } }].each do |payload|
      @client.mutation_result = { 'mergePullRequest' => payload }
      error = assert_raises(AgentWorkflows::Error) { @merge.call(head: HEAD, walkthrough: 17) }
      assert_match(/did not confirm.*inspect live PR state/, error.message)
    end
    assert_equal 3, @client.mutations.length
  end

  def test_snapshot_failure_does_not_submit
    @client.snapshots = [AgentWorkflows::Error.new('Snapshot unavailable')]
    assert_blocked(/Snapshot unavailable/)
  end
end
