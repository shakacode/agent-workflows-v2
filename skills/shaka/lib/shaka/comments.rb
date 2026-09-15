# frozen_string_literal: true

require_relative 'error'

module Shaka
  # Gives public PR readers only bodies from actors with repository write access.
  class Comments
    TRUSTED_PERMISSIONS = %w[write maintain admin].freeze
    LOGIN = /\A[A-Za-z0-9](?:[A-Za-z0-9-]{0,38})\z/
    KINDS = { 'issue_comments' => 'issue_comment', 'review_summaries' => 'review_summary',
              'inline_comments' => 'inline_comment' }.freeze

    def initialize(github)
      @github = github
    end

    def call(issue_only: false)
      head = issue_only ? nil : open_head
      verify_issue if issue_only
      private_repo = repository_private?
      items = fetch_items(issue_only:)
      permissions = private_repo ? {} : author_permissions(items.values.flatten)
      verify_head(head) unless issue_only
      present(items, permissions, private_repo, head)
    end

    private

    def open_head
      pull = @github.snapshot
      raise Error, 'PR must be open for a comment read.' unless pull['state'] == 'OPEN'

      pull['headRefOid']
    end

    def verify_head(head)
      raise Error, 'PR head changed or closed during comment read.' unless open_head == head
    end

    def verify_issue
      issue = @github.api("repos/#{@github.repository}/issues/#{@github.number}")
      raise Error, 'Expected a GitHub issue, not a pull request.' if issue.key?('pull_request')
    end

    def repository_private?
      metadata = @github.api("repos/#{@github.repository}")
      raise Error, 'Repository visibility is unavailable.' unless [true, false].include?(metadata['private'])

      metadata['private']
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

    def author_permissions(items)
      prefix = "repos/#{@github.repository}"
      items.filter_map { |item| item.dig('user', 'login') }.uniq.to_h do |login|
        [login, permission_for(prefix, login)]
      end
    end

    def permission_for(prefix, login)
      return unless login.is_a?(String) && login.match?(LOGIN)

      result = @github.api("#{prefix}/collaborators/#{login}/permission")
      return unless result.dig('user', 'login')&.casecmp?(login)

      result['permission']
    rescue Error
      nil
    end

    def present(items, permissions, private_repo, head)
      excluded = []
      kept = items.to_h do |key, rows|
        [key, filter(rows, KINDS.fetch(key), permissions, private_repo, excluded)]
      end
      { 'visibility' => private_repo ? 'private' : 'public', 'head' => head,
        'excluded_interactions' => excluded }.merge(kept)
    end

    def filter(items, kind, permissions, private_repo, excluded)
      items.filter_map do |item|
        author = item.dig('user', 'login')
        if private_repo || TRUSTED_PERMISSIONS.include?(permissions[author])
          kept_record(item, kind, author)
        else
          excluded << excluded_record(item, kind, author)
          nil
        end
      end
    end

    def kept_record(item, kind, author)
      row = { 'id' => item['id'], 'author' => author, 'body' => item['body'], 'url' => item['html_url'] }
      row['state'] = item['state'] if kind == 'review_summary'
      row['commit_id'] = item['commit_id'] if kind == 'review_summary'
      row['line'] = item['line'] if kind == 'inline_comment'
      row
    end

    def excluded_record(item, kind, author)
      { 'kind' => kind, 'id' => item['id'], 'author' => author,
        'url' => item['html_url'], 'body_withheld' => !item['body'].to_s.empty? }
    end
  end
end
