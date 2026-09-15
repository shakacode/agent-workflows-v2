# frozen_string_literal: true

require_relative 'github_helper'
require 'shaka/comments'

module CommentsFixture
  include GitHubHelper

  def comment(id:, author:, body:)
    { 'id' => id, 'user' => { 'login' => author }, 'body' => body,
      'html_url' => "https://github.com/owner/repo/pull/42#issuecomment-#{id}" }
  end

  def packet(issue: [], reviews: [], inline: [], private_repo: false, permissions: [])
    github = client(snapshot_response, response({ 'private' => private_repo }),
                    response([issue]), response([reviews]), response([inline]),
                    *permissions, snapshot_response, response({ 'private' => private_repo }))
    Shaka::Comments.new(github).call
  end

  def issue_packet(comments:, permissions: [])
    github = client(response({ 'number' => 42 }), response({ 'private' => false }),
                    response([comments]), *permissions, response({ 'private' => false }))
    Shaka::Comments.new(github).call(issue_only: true)
  end

  def bodies(result, key)
    result.fetch(key).map { |item| item['body'] }
  end

  def permission(login, level)
    response({ 'permission' => level, 'user' => { 'login' => login } })
  end

  def assert_inline_location(result, path:, original_line:, commit_id:)
    inline = result['inline_comments'].first
    assert_equal path, inline['path']
    assert_equal original_line, inline['original_line']
    assert_equal commit_id, inline['commit_id']
  end
end
