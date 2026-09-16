# frozen_string_literal: true

require_relative 'comments_fixture'

class CommentTeamsTest < Minitest::Test
  include CommentsFixture

  def active(login, state: 'active', url_login: login)
    response({ 'url' => "https://api.github.com/teams/7/memberships/#{url_login}", 'state' => state })
  end

  def test_direct_membership_accepts_only_active_same_login
    github = client(active('member'), active('pending', state: 'pending'), active('other', url_login: 'stranger'))
    result = Shaka::CommentTeams.new(github).trusted(%w[member pending other], [%w[owner maintainers]])

    assert_equal Set['member'], result[:trusted]
    assert_equal 3, @calls.length
    assert(@calls.all? { |argv, _| argv.join(' ').include?('/teams/maintainers/memberships/') })
  end

  def test_many_outsiders_use_one_team_list_and_one_rest_confirmation
    logins = (1..30).map { |id| "outside#{id}" } + ['member']
    members = [{ 'login' => 'member', 'type' => 'User' }]
    github = client(response(members), active('member'))
    result = Shaka::CommentTeams.new(github).trusted(logins, [%w[owner maintainers]])

    assert_equal Set['member'], result[:trusted]
    assert_batched_team_calls
  end

  def assert_batched_team_calls
    assert_equal 2, @calls.length
    assert_equal 'orgs/owner/teams/maintainers/members?per_page=100&page=1', @calls.first.first[2]
    assert_equal 'member', @calls.last.first[2].split('/').last
  end

  def test_mismatched_list_login_never_reaches_membership_api
    github = client(response([{ 'login' => 'stranger', 'type' => 'User' }]))
    result = Shaka::CommentTeams.new(github).trusted((1..9).map { |id| "person#{id}" },
                                                     [%w[owner maintainers]])

    assert_empty result[:trusted]
    assert_equal 1, @calls.length
  end

  def test_unavailable_membership_is_not_trusted
    github = client(response({ 'message' => 'not found' }, status: 1))
    result = Shaka::CommentTeams.new(github).trusted(['person'], [%w[owner maintainers]])
    assert_empty result[:trusted]
    assert_equal Set['person'], result[:unavailable]
  end

  def test_unavailable_confirmation_of_listed_member_is_visible
    listed = response([{ 'login' => 'member', 'type' => 'User' }])
    github = client(listed, response({ 'message' => 'unavailable' }, status: 1))
    logins = (1..9).map { |id| "person#{id}" } + ['member']
    result = Shaka::CommentTeams.new(github).trusted(logins, [%w[owner maintainers]])

    assert_empty result[:trusted]
    assert_equal Set['member'], result[:unavailable]
  end

  def test_unavailable_list_stops_instead_of_claiming_complete_evidence
    github = client(response({ 'message' => 'unavailable' }))
    error = assert_raises(Shaka::Error) do
      Shaka::CommentTeams.new(github).trusted((1..9).map { |id| "person#{id}" },
                                              [%w[owner maintainers]])
    end

    assert_match(/list evidence is unavailable/, error.message)
  end

  def test_many_author_team_pairs_are_bounded_by_team_list_calls
    logins = (1..150).map { |id| "person#{id}" }
    teams = (1..20).map { |id| ['owner', "team#{id}"] }
    responses = Array.new(20) { response([]) }
    github = client(*responses)

    assert_empty Shaka::CommentTeams.new(github).trusted(logins, teams)[:trusted]
    assert_equal 20, @calls.length
  end

  def test_too_many_teams_stop_before_api_calls
    github = client
    teams = (1..21).map { |id| ['owner', "team#{id}"] }

    assert_raises(Shaka::Error) { Shaka::CommentTeams.new(github).trusted(['person'], teams) }
    assert_empty @calls
  end

  def test_member_listing_stops_after_bounded_pages
    members = Array.new(100) { |id| { 'login' => "person#{id}", 'type' => 'User' } }
    responses = Array.new(11) { response(members) }
    github = client(*responses)
    logins = (1..9).map { |id| "outside#{id}" }

    error = assert_raises(Shaka::Error) do
      Shaka::CommentTeams.new(github).trusted(logins, [%w[owner maintainers]])
    end

    assert_match(/list evidence is unavailable/, error.message)
    assert_equal 11, @calls.length
  end
end
