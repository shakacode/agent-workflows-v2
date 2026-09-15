# frozen_string_literal: true

require_relative 'error'
require_relative 'comment_writers'

module Shaka
  # Screens public comment prose using GitHub's repository permission evidence.
  class CommentAuthors
    TRUSTED_PERMISSIONS = %w[write maintain admin].freeze
    KINDS = { 'issue_comments' => 'issue_comment', 'review_summaries' => 'review_summary',
              'inline_comments' => 'inline_comment' }.freeze

    def initialize(github, private_repo:)
      @github = github
      @private_repo = private_repo
    end

    def screen(items, thread_index: {})
      items.fetch('inline_comments', []).each { |item| thread_metadata(item, thread_index) }
      logins = items.values.flatten.filter_map { |item| author(item) }
      permissions = @private_repo ? {} : CommentWriters.new(@github).permissions(logins)
      excluded = []
      kept = items.to_h do |key, rows|
        [key, filter(rows, KINDS.fetch(key), permissions, excluded, thread_index)]
      end
      { 'excluded_interactions' => excluded }.merge(kept)
    end

    private

    def author(item)
      user = item['user']
      user['login'] if user.is_a?(Hash)
    end

    def filter(items, kind, permissions, excluded, thread_index)
      items.filter_map do |item|
        login = author(item)
        thread = thread_metadata(item, thread_index) if kind == 'inline_comment'
        if @private_repo || TRUSTED_PERMISSIONS.include?(permissions[login])
          kept_record(item, kind, login, thread)
        else
          excluded << excluded_record(item, kind, login, thread, permissions[login] == 'unavailable')
          nil
        end
      end
    end

    def thread_metadata(item, index)
      meta = index[item['id']] || index[item['in_reply_to_id']]
      raise Error, 'Inline comment has no review-thread metadata.' unless meta

      meta
    end

    def kept_record(item, kind, login, thread)
      row = { 'id' => item['id'], 'author' => login, 'body' => item['body'], 'url' => item['html_url'] }
      row['state'] = item['state'] if kind == 'review_summary'
      row['commit_id'] = item['commit_id'] if kind == 'review_summary'
      row.merge!(inline_location(item)).merge!(thread) if kind == 'inline_comment'
      row
    end

    def inline_location(item)
      { 'path' => item['path'], 'line' => item['line'], 'original_line' => item['original_line'],
        'commit_id' => item['commit_id'], 'in_reply_to_id' => item['in_reply_to_id'] }
    end

    def excluded_record(item, kind, login, thread, unavailable)
      row = { 'kind' => kind, 'id' => item['id'], 'author' => login,
              'url' => item['html_url'], 'body_withheld' => !item['body'].to_s.empty?,
              'verification_unavailable' => unavailable }
      row.merge!(thread) if kind == 'inline_comment'
      row
    end
  end
end
