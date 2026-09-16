# frozen_string_literal: true

require_relative 'error'
require_relative 'github_login'

module Shaka
  # Uses direct checks for small discussions and one member list per larger team.
  class CommentTeams
    DIRECT_PAIR_LIMIT = 8
    MAX_TEAMS = 20
    TEAM_PAGE_SIZE = 100
    MAX_TEAM_PAGES = 10

    def initialize(github)
      @github = github
    end

    def trusted(logins, teams)
      valid = GitHubLogin.valid(logins)
      return empty_result if valid.empty? || teams.empty?

      confirmed(candidates(valid, teams))
    end

    private

    def empty_result
      { trusted: Set.new, unavailable: Set.new }
    end

    def candidates(logins, teams)
      raise Error, 'Too many configured teams for a bounded trust read.' if teams.length > MAX_TEAMS

      count = logins.length * teams.length
      listed = count > DIRECT_PAIR_LIMIT
      listed ? listed_pairs(logins, teams) : direct_pairs(logins, teams)
    end

    def confirmed(pairs)
      result = empty_result
      pairs.each do |login, owner, slug|
        next if result[:trusted].include?(login)

        state = active_member?(owner, slug, login)
        result[:trusted].add(login) if state == true
        result[:unavailable].add(login) if state.nil?
      end
      result
    end

    def direct_pairs(logins, teams)
      logins.product(teams).map { |login, (owner, slug)| [login, owner, slug] }
    end

    def listed_pairs(logins, teams)
      teams.flat_map do |owner, slug|
        members = listed_members(owner, slug)
        logins.filter_map { |login| [login, owner, slug] if members.include?(login) }
      end
    rescue Error
      raise Error, 'Team-member list evidence is unavailable.'
    end

    def listed_members(owner, slug)
      logins = Set.new
      (1..(MAX_TEAM_PAGES + 1)).each do |page|
        rows = team_page(owner, slug, page)
        logins.merge(rows.filter_map { |member| member_login(member) })
        break if rows.length < TEAM_PAGE_SIZE
      end
      logins
    end

    def team_page(owner, slug, page)
      rows = @github.api_list("orgs/#{owner}/teams/#{slug}/members?per_page=#{TEAM_PAGE_SIZE}&page=#{page}")
      raise Error, 'Team-member list is malformed.' unless rows.length <= TEAM_PAGE_SIZE && rows.all?(Hash)
      raise Error, 'Team-member list exceeds the page limit.' if page > MAX_TEAM_PAGES && !rows.empty?

      rows
    end

    def member_login(member)
      login = member['login']
      login.downcase if member['type'] == 'User' && login.is_a?(String) && login.match?(GitHubLogin::PATTERN)
    end

    def active_member?(owner, slug, login)
      result = @github.api("orgs/#{owner}/teams/#{slug}/memberships/#{login}")
      url = result['url']
      result['state'] == 'active' && url.is_a?(String) &&
        url.downcase.end_with?("/memberships/#{login.downcase}")
    rescue Error
      nil
    end
  end
end
