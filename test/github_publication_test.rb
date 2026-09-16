# frozen_string_literal: true

require_relative 'github_helper'

# Publishing a description or reply must read back both the stored body and the rendered output.
class GitHubPublicationTest < Minitest::Test
  include GitHubHelper

  BODY = "🤖 Codex · OpenAI · terra · low\n\nA summary.\n"
  MANAGED = "<!-- shaka:begin -->\n#{BODY}<!-- shaka:end -->".freeze

  def pull_response(body)
    response({ 'id' => 1, 'number' => 42, 'body' => body })
  end

  def html_response(html)
    [html, 'private stderr must not be disclosed', STATUS.new(0)]
  end

  def sent_body(index = 2) = JSON.parse(@calls[index].last)['body']

  def sent_method(index = 2)
    argv = @calls[index].first
    argv[argv.index('--method') + 1]
  end

  def test_description_keeps_content_other_authors_appended
    existing = "old\n\n<!-- coderabbit -->\nSummary by CodeRabbit"
    github = client(pull_response(existing), html_response('<p>ok</p>'), pull_response("#{MANAGED}\n\n#{existing}"))
    github.description(body: BODY)
    sent = sent_body
    assert_equal "#{MANAGED}\n\n#{existing}", sent
    assert_includes sent, 'Summary by CodeRabbit'
  end

  def test_republishing_replaces_only_the_managed_region
    existing = "#{MANAGED}\n\nSummary by CodeRabbit"
    updated = "<!-- shaka:begin -->\nNew text.\n<!-- shaka:end -->\n\nSummary by CodeRabbit"
    github = client(pull_response(existing), html_response('<p>ok</p>'), pull_response(updated))
    github.description(body: "New text.\n")
    assert_equal updated, sent_body
    assert_equal 1, sent_body.scan('<!-- shaka:begin -->').size
  end

  def test_stored_body_that_does_not_match_the_submission_is_reported
    github = client(pull_response(''), html_response('<p>ok</p>'), pull_response('something else'))
    assert_raises(Shaka::Error) { github.description(body: BODY) }
  end

  def test_a_table_that_github_does_not_render_is_reported
    table = "#{BODY}\n| A | B |\n| --- | --- |\n| 1 | 2 |\n"
    github = client(pull_response(''), html_response('<p>| A | B |</p>'))
    error = assert_raises(Shaka::Error) { github.description(body: table) }
    assert_includes error.message, 'table'
  end

  def test_a_rendered_table_passes_the_readback
    table = "#{BODY}\n| A | B |\n| --- | --- |\n| 1 | 2 |\n"
    managed = "<!-- shaka:begin -->\n#{table}<!-- shaka:end -->"
    github = client(pull_response(''), html_response('<table><tr><td>1</td></tr></table>'), pull_response(managed))
    assert_equal managed, github.description(body: table)['body']
  end

  def test_escape_sequences_surviving_into_the_rendered_output_are_reported
    github = client(pull_response(''), html_response('<p>A summary.\n\nMore.</p>'))
    error = assert_raises(Shaka::Error) { github.description(body: BODY) }
    assert_includes error.message, 'escape sequence'
  end

  def test_replies_reuse_their_keyed_comment_instead_of_duplicating_it
    listed = response([{ 'id' => 7, 'body' => "<!-- shaka:reply:fix-1 -->\nold" }])
    github = client(listed, html_response('<p>ok</p>'),
                    response({ 'id' => 7, 'body' => "<!-- shaka:reply:fix-1 -->\n#{BODY}" }))
    github.reply(body: BODY, key: 'fix-1')
    assert_equal 'PATCH', sent_method
    assert_includes @calls[2].first.join(' '), 'issues/comments/7'
  end

  def test_a_reply_without_an_existing_comment_is_created_once
    github = client(response([]), html_response('<p>ok</p>'),
                    response({ 'id' => 9, 'body' => "<!-- shaka:reply:fix-1 -->\n#{BODY}" }))
    github.reply(body: BODY, key: 'fix-1')
    assert_equal 'POST', sent_method
  end

  def test_an_invalid_reply_key_never_contacts_github
    ['', 'has space', 'a' * 65, nil].each do |key|
      assert_raises(Shaka::Error) { client.reply(body: BODY, key: key) }
      assert_empty @calls
    end
  end
end
