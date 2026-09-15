# frozen_string_literal: true

require_relative 'error'

module Shaka
  # Applies native GitHub gates; the calling skill must establish merge authority.
  class Merge
    MUTATION = <<~GRAPHQL
      mutation($id: ID!, $head: GitObjectID!) {
        mergePullRequest(input: {pullRequestId: $id, expectedHeadOid: $head, mergeMethod: SQUASH}) {
          pullRequest { state headRefOid merged mergeCommit { oid } }
        }
      }
    GRAPHQL

    def initialize(github)
      @github = github
    end

    def call(head:, walkthrough:)
      raise Error, 'Expected a full commit SHA' unless head.is_a?(String) && head.match?(/\A[0-9a-f]{40}\z/)

      verify_snapshot(@github.snapshot, head)
      verify_checks(@github.required_checks)
      verify_walkthrough(@github.review(walkthrough), head, walkthrough)
      current = @github.snapshot
      verify_snapshot(current, head)
      submit(current.fetch('id'), head)
    end

    private

    def verify_snapshot(pull, head)
      raise Error, 'PR head changed; refresh verification and walkthrough' unless pull['headRefOid'] == head
      raise Error, 'PR must be open and not a draft' unless pull['state'] == 'OPEN' && pull['isDraft'] == false
      raise Error, 'GitHub PR identity is missing' unless pull['id'].is_a?(String) && !pull['id'].empty?

      verify_submission_mode(pull)
      verify_native_state(pull)
    end

    def verify_submission_mode(pull)
      raise Error, 'Native protection must be enforced for this actor' unless pull['viewerCanMergeAsAdmin'] == false
      unless pull['isMergeQueueEnabled'] == false && pull['isInMergeQueue'] == false
        raise Error, 'Merge queues are unsupported by this pilot'
      end
      return if pull.key?('autoMergeRequest') && pull['autoMergeRequest'].nil?

      raise Error, 'Existing or unknown delayed auto-merge blocks immediate merge'
    end

    def verify_native_state(pull)
      unless pull['mergeStateStatus'] == 'CLEAN'
        raise Error, "GitHub merge state is not CLEAN: #{pull['mergeStateStatus'].inspect}"
      end
      return if pull.key?('reviewDecision') && [nil, 'APPROVED'].include?(pull['reviewDecision'])

      raise Error, 'Required reviews are not satisfied or their state is unknown'
    end

    def verify_checks(checks)
      unless checks.is_a?(Array) && !checks.empty?
        raise Error, 'No observable required checks; native readiness is unknown'
      end

      checks.each do |check|
        next if passing_check?(check)

        raise Error, "Required check is not passing or is malformed: #{check.inspect}"
      end
    end

    def passing_check?(check)
      return false unless check.is_a?(Hash) && check['name'].is_a?(String) && !check['name'].strip.empty?

      case check['state']
      when 'SUCCESS' then check['bucket'] == 'pass'
      when 'NEUTRAL', 'SKIPPED' then check['bucket'] == 'skipping'
      else false
      end
    end

    def verify_walkthrough(review, head, id)
      unless review.is_a?(Hash) && review['id'].to_s == id.to_s && review['commit_id'] == head
        raise Error, 'Walkthrough must identify a review on this PR at the expected head'
      end
      return if review['state'] == 'COMMENTED' && review['body'].is_a?(String) && !review['body'].strip.empty?

      raise Error, 'Walkthrough must be a submitted COMMENT review with a nonempty body'
    end

    def submit(id, head)
      result = @github.graphql(MUTATION, { 'id' => id, 'head' => head })
      payload = result['mergePullRequest']
      pr = payload['pullRequest'] if payload.is_a?(Hash)
      unless pr.is_a?(Hash) && pr['merged'] == true && pr['state'] == 'MERGED' && pr['headRefOid'] == head
        raise Error, 'GitHub did not confirm merging the expected head'
      end

      pr
    rescue Error => e
      raise Error, "#{e.message}; inspect live PR state before retrying a merge"
    end
  end
end
