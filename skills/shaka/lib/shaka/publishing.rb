# frozen_string_literal: true

require 'json'
require_relative 'error'

module Shaka
  # Publishes rendered Markdown, checking GitHub's own rendering before anything is written
  # and confirming the stored bytes afterwards.
  module Publishing
    OPEN_MARK = '<!-- shaka:begin -->'
    CLOSE_MARK = '<!-- shaka:end -->'
    ESCAPE = /\\[nrt]/
    SEPARATOR = /\A\s*\|[\s|:-]*-{3}[\s|:-]*\|\s*\z/

    def description(body:)
      merged = merge(pull['body'].to_s, publishable(body))
      verify_rendering(merged)
      confirmed(api(pull_path, method: 'PATCH', fields: { body: merged }), merged)
    end

    def reply(body:, key:)
      mark = reply_mark(key)
      content = "#{mark}\n#{publishable(body)}"
      existing = replies.find { |comment| comment['body'].to_s.include?(mark) }
      verify_rendering(content)
      confirmed(write_reply(existing, content), content)
    end

    # A body GitHub will not render correctly must never reach the pull request.
    def verify_rendering(body)
      html = markdown(body)
      raise Error, 'Rendered output contains a literal escape sequence; supply real line breaks.' if html.match?(ESCAPE)

      expected = body.lines.count { |line| line.match?(SEPARATOR) }
      rendered = html.scan('<table').size
      return if rendered >= expected

      raise Error, "GitHub rendered #{rendered} of #{expected} table(s); check the separator column count."
    end

    def markdown(text)
      capture(['gh', 'api', 'markdown', '--method', 'POST', '--input', '-'],
              input: JSON.generate({ mode: 'gfm', text: text }))
    end

    private

    # Only the marked region is ours; anything a person or another bot added stays.
    def merge(existing, body)
      managed = "#{OPEN_MARK}\n#{body}#{CLOSE_MARK}"
      return managed if existing.strip.empty?
      return "#{managed}\n\n#{existing}" unless existing.include?(OPEN_MARK) && existing.include?(CLOSE_MARK)

      prefix, rest = existing.split(OPEN_MARK, 2)
      "#{prefix}#{managed}#{rest.split(CLOSE_MARK, 2).last}"
    end

    def write_reply(existing, content)
      path = if existing
               "repos/#{@repository}/issues/comments/#{positive_integer(existing['id'])}"
             else
               "repos/#{@repository}/issues/#{@number}/comments"
             end
      api(path, method: existing ? 'PATCH' : 'POST', fields: { body: content })
    end

    def replies
      result = execute(['gh', 'api', "repos/#{@repository}/issues/#{@number}/comments",
                        '--method', 'GET', '--input', '-'], input: '{}')
      raise Error, 'GitHub comment listing must be an array.' unless result.is_a?(Array)

      result
    end

    def reply_mark(key)
      raise Error, 'Expected a short reply key of letters, digits, hyphens or underscores.' unless
        key.is_a?(String) && key.match?(/\A[\w-]{1,64}\z/)

      "<!-- shaka:reply:#{key} -->"
    end

    def pull = api(pull_path)
    def pull_path = "repos/#{@repository}/pulls/#{@number}"

    def publishable(body)
      body = utf8(body)
      raise Error, 'Publication body must be nonempty.' if body.strip.empty?

      body
    end

    def confirmed(published, expected)
      raise Error, 'GitHub API response must be an object.' unless published.is_a?(Hash)
      return published if published['body'] == expected

      raise Error, 'The stored body does not match what was submitted; inspect the pull request before retrying.'
    end
  end
end
