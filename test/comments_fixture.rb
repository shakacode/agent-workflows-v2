# frozen_string_literal: true

require_relative 'github_helper'
require 'shaka/comments'

module CommentsFixture
  include GitHubHelper

  def comment(id:, author:, body:)
    { 'id' => id, 'user' => { 'login' => author }, 'body' => body,
      'html_url' => "https://github.com/owner/repo/pull/42#issuecomment-#{id}" }
  end

  def packet(issue: [], reviews: [], inline: [], threads: [], **options)
    private_repo = options.fetch(:private_repo, false)
    threads = default_threads(inline) if threads.empty?
    pages = options.fetch(:thread_pages) { [thread_response(threads)] }
    github = client(snapshot_response, response({ 'private' => private_repo }),
                    *comment_responses(issue, reviews, inline), *pages,
                    *prefilter_pages(private_repo, options, issue + reviews + inline), *options.fetch(:permissions, []),
                    *finish_context(private_repo))
    Shaka::Comments.new(github).call(expected_head: HEAD)
  end

  def default_threads(inline)
    inline.map { |item| thread(id: "T#{item['id']}", resolved: false, comments: [item['id']]) }
  end

  def finish_context(private_repo)
    [snapshot_response, response({ 'private' => private_repo })]
  end

  def comment_responses(issue, reviews, inline)
    [response([issue]), response([reviews]), response([inline])]
  end

  def authors(items)
    items.filter_map do |item|
      user = item['user']
      user['login'] if user.is_a?(Hash)
    end.uniq
  end

  def prefilter_pages(private_repo, options, items)
    return [] if private_repo

    logins = authors(items).select { |login| login.is_a?(String) && login.match?(Shaka::CommentWriters::LOGIN) }
    return [] if logins.length <= Shaka::CommentWriters::DIRECT_LIMIT

    writers = options.fetch(:writers, logins)
    logins.each_slice(Shaka::CommentWriters::BATCH_SIZE).map { |slice| graph_writer_response(slice, writers) }
  end

  def graph_writer_response(logins, writers)
    fields = logins.each_with_index.to_h do |login, index|
      edges = writers.include?(login) ? [{ 'node' => { 'login' => login }, 'permission' => 'WRITE' }] : []
      ["u#{index}", { 'edges' => edges }]
    end
    response({ 'data' => { 'repository' => fields } })
  end

  def issue_packet(comments:, permissions: [])
    github = client(response({ 'number' => 42 }), response({ 'private' => false }),
                    response([comments]), *prefilter_pages(false, {}, comments), *permissions,
                    response({ 'private' => false }))
    Shaka::Comments.new(github).call(issue_only: true)
  end

  def bodies(result, key)
    result.fetch(key).map { |item| item['body'] }
  end

  def permission_call_count
    @calls.count { |argv, _| argv.join(' ').include?('/permission') }
  end

  def permission(login, level)
    response({ 'permission' => level, 'user' => { 'login' => login } })
  end

  def thread_response(threads, more: false, cursor: nil)
    connection = { 'nodes' => threads, 'pageInfo' => { 'hasNextPage' => more, 'endCursor' => cursor } }
    response({ 'data' => { 'repository' => { 'pullRequest' => { 'reviewThreads' => connection } } } })
  end

  def thread(id:, resolved:, comments:)
    { 'id' => id, 'isResolved' => resolved,
      'comments' => { 'nodes' => comments.map { |comment_id| { 'fullDatabaseId' => comment_id.to_s } },
                      'pageInfo' => { 'hasNextPage' => false } } }
  end

  def two_thread_pages
    [thread_response([thread(id: 'T1', resolved: true, comments: [50])], more: true, cursor: 'next'),
     thread_response([thread(id: 'T2', resolved: false, comments: [51])])]
  end

  def assert_inline_location(result, path:, original_line:, commit_id:)
    inline = result['inline_comments'].first
    assert_equal path, inline['path']
    assert_equal original_line, inline['original_line']
    assert_equal commit_id, inline['commit_id']
  end
end
