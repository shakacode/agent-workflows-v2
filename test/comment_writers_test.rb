# frozen_string_literal: true

require_relative 'comments_fixture'

class CommentWritersTest < Minitest::Test
  include CommentsFixture

  def test_many_outsiders_do_not_consume_individual_permission_lookups
    outside = (1..30).map { |id| comment(id: id, author: "outside#{id}", body: 'Noise') }
    maintainer = comment(id: 31, author: 'maintainer', body: 'Review this')
    result = packet(issue: outside + [maintainer], writers: ['maintainer'],
                    permissions: [permission('maintainer', 'write')])

    assert_equal ['Review this'], bodies(result, 'issue_comments')
    assert_equal 30, result['excluded_interactions'].length
    assert_equal(1, @calls.count { |argv, _| argv.join(' ').include?('/permission') })
  end

  def test_unavailable_writer_listing_blocks_public_packet
    maintainer = comment(id: 32, author: 'maintainer', body: 'Check this')
    github = client(snapshot_response, response({ 'private' => false }), response([[maintainer]]),
                    response([[]]), response([[]]), thread_response([]), response({}, status: 4))

    error = assert_raises(Shaka::Error) { Shaka::Comments.new(github).call(expected_head: HEAD) }
    assert_match(/writer evidence is unavailable/, error.message)
  end
end
