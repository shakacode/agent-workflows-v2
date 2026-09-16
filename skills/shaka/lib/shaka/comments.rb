# frozen_string_literal: true

require_relative 'error'
require_relative 'comment_authors'
require_relative 'comment_threads'

module Shaka
  # Reads one issue or PR discussion at a stable visibility and PR head.
  class Comments
    def initialize(github)
      @github = github
    end

    def call(issue_only: false, expected_head: nil)
      head = issue_only ? issue_head(expected_head) : pr_head(expected_head)
      visibility = repository_visibility
      items = fetch_items(issue_only:)
      threads, index = issue_only ? [[], {}] : CommentThreads.new(@github).call
      screened = CommentAuthors.new(@github, public_repo: visibility == 'public').screen(items, thread_index: index)
      verify_context(head, visibility)
      { 'visibility' => visibility, 'head' => head,
        'review_threads' => threads }.merge(screened)
    end

    private

    def pr_head(expected)
      raise Error, 'Expected a full PR head.' unless expected.is_a?(String) && expected.match?(/\A[0-9a-f]{40}\z/)

      head = open_head
      return head if expected == head

      raise Error, 'Comments are not at the expected head.'
    end

    def issue_head(expected)
      raise Error, 'Issue comments have no expected PR head.' unless expected.nil?

      issue = @github.api("repos/#{@github.repository}/issues/#{@github.number}")
      raise Error, 'Expected a GitHub issue, not a pull request.' if issue.key?('pull_request')

      nil
    end

    def open_head
      pull = @github.snapshot
      raise Error, 'PR must be open for a comment read.' unless pull['state'] == 'OPEN'

      pull['headRefOid']
    end

    def verify_context(head, visibility)
      raise Error, 'PR head changed or closed during comment read.' if head && open_head != head
      raise Error, 'Repository visibility changed during comment read.' unless repository_visibility == visibility
    end

    def repository_visibility
      metadata = @github.api("repos/#{@github.repository}")
      visibility = metadata['visibility']
      raise Error, 'Repository visibility is unavailable.' unless %w[public private internal].include?(visibility)

      visibility
    end

    def fetch_items(issue_only:)
      prefix = "repos/#{@github.repository}"
      number = @github.number
      items = { 'issue_comments' => fetch_page("#{prefix}/issues/#{number}/comments") }
      return items if issue_only

      items['review_summaries'] = fetch_page("#{prefix}/pulls/#{number}/reviews")
      items['inline_comments'] = fetch_page("#{prefix}/pulls/#{number}/comments")
      items
    end

    def fetch_page(path)
      pages = @github.paginated(path)
      unless pages.is_a?(Array) && pages.all? { |page| page.is_a?(Array) && page.all?(Hash) }
        raise Error, 'GitHub comment response must contain arrays of objects.'
      end

      pages.flatten(1)
    end
  end
end
