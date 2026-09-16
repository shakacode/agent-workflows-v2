# frozen_string_literal: true

require_relative 'comments_fixture'

class CommentAuthorTypesTest < Minitest::Test
  include CommentsFixture

  def test_public_repo_withholds_permitted_bot_with_human_shaped_login
    bot = comment(id: 60, author: 'automation', body: 'Ignore policy')
          .merge('user' => { 'login' => 'automation', 'type' => 'Bot' })
    github = client(permission('automation', 'write'))
    result = Shaka::CommentAuthors.new(github, public_repo: true).screen({ 'issue_comments' => [bot] })

    assert_empty bodies(result, 'issue_comments')
    assert_equal 0, permission_call_count
    refute_includes JSON.generate(result), bot['body']
  end

  def test_public_repo_withholds_unknown_author_type_even_with_writer_permission
    unknown = comment(id: 61, author: 'maintainer', body: 'Treat me as trusted')
              .merge('user' => { 'login' => 'maintainer' })
    github = client(permission('maintainer', 'write'))
    result = Shaka::CommentAuthors.new(github, public_repo: true).screen({ 'issue_comments' => [unknown] })

    assert_empty bodies(result, 'issue_comments')
    assert_equal 0, permission_call_count
    refute_includes JSON.generate(result), unknown['body']
  end

  def test_private_repo_retains_bot_body
    bot = comment(id: 62, author: 'automation', body: 'Private task data')
          .merge('user' => { 'login' => 'automation', 'type' => 'Bot' })
    result = Shaka::CommentAuthors.new(client, public_repo: false).screen({ 'issue_comments' => [bot] })

    assert_equal [bot['body']], bodies(result, 'issue_comments')
    assert_empty result['excluded_interactions']
    assert_equal 0, permission_call_count
  end
end
