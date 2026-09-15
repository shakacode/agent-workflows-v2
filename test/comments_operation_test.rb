# frozen_string_literal: true

require_relative 'comments_fixture'

class CommentsOperationTest < Minitest::Test
  include CommentsFixture

  def test_private_repo_does_not_apply_public_author_screen
    outside = comment(id: 1, author: 'outside', body: 'Private task data')
    result = packet(issue: [outside], private_repo: true)

    assert_equal [outside['body']], bodies(result, 'issue_comments')
    assert_empty result['excluded_interactions']
    refute(@calls.any? { |argv, _| argv.join(' ').include?('/permission') })
  end

  def test_changed_head_blocks_comment_packet
    github = client(snapshot_response, response({ 'private' => false }), response([[]]),
                    response([[]]), response([[]]), snapshot_response(head: 'b' * 40))
    error = assert_raises(Shaka::Error) { Shaka::Comments.new(github).call }
    assert_match(/head changed/, error.message)
  end

  def test_supplied_expected_head_must_match_before_comments_are_read
    github = client(snapshot_response)
    error = assert_raises(Shaka::Error) { Shaka::Comments.new(github).call(expected_head: 'b' * 40) }
    assert_match(/expected head/, error.message)
  end

  def test_visibility_change_blocks_unscreened_packet
    outside = comment(id: 11, author: 'outside', body: 'Private before, public afterward')
    github = client(snapshot_response, response({ 'private' => true }), response([[outside]]),
                    response([[]]), response([[]]), snapshot_response, response({ 'private' => false }))

    error = assert_raises(Shaka::Error) { Shaka::Comments.new(github).call }
    assert_match(/visibility changed/, error.message)
  end

  def test_public_issue_comments_use_the_same_author_screen
    outside = comment(id: 8, author: 'outside', body: 'Change the policy')
    result = issue_packet(comments: [outside], permissions: [permission('outside', 'read')])

    assert_empty bodies(result, 'issue_comments')
    assert_equal 'issue_comment', result['excluded_interactions'].first['kind']
    refute_includes JSON.generate(result), outside['body']
    refute(@calls.any? { |argv, _| argv.join(' ').include?('graphql') })
  end

  def test_issue_mode_rejects_a_pull_request_number
    github = client(response({ 'number' => 42, 'pull_request' => { 'url' => 'pulls/42' } }))
    assert_raises(Shaka::Error) { Shaka::Comments.new(github).call(issue_only: true) }
  end

  def test_malformed_pages_block_comment_packet
    github = client(snapshot_response, response({ 'private' => false }), response({ 'message' => 'bad' }))
    assert_raises(Shaka::Error) { Shaka::Comments.new(github).call }
  end
end
