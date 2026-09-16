# frozen_string_literal: true

require_relative 'error'
require_relative 'bounded_list'
require_relative 'github_login'

module Shaka
  # Uses direct checks for small discussions and one member list per larger team.
  class CommentTeams
    DIRECT_PAIR_LIMIT = 32
    MAX_TEAMS = 20
    MAX_TEAM_PAGES = 10
    MAX_FALLBACK_PAIRS = 100

    def initialize(github)
      @github = github
      @readable_teams = {}
    end

    def trusted(logins, teams)
      valid = GitHubLogin.valid(logins)
      return empty_result if valid.empty? || teams.empty?

      @fallback_count = 0
      return listed_confirmed(valid, teams) if listed?(valid, teams)

      confirmed(direct_pairs(valid, teams))
    end

    private

    def empty_result
      { trusted: Set.new, unavailable: Set.new }
    end

    def listed?(logins, teams)
      raise Error, 'Too many configured teams for a bounded trust read.' if teams.length > MAX_TEAMS

      logins.length * teams.length > DIRECT_PAIR_LIMIT
    end

    def confirmed(pairs, result = empty_result)
      pairs.each do |login, owner, slug|
        next if result[:trusted].include?(login)

        state = membership_state(owner, slug, login)
        result[:trusted].add(login) if state == true
        result[:unavailable].add(login) if state.nil?
      end
      result
    end

    def direct_pairs(logins, teams)
      logins.product(teams).map { |login, (owner, slug)| [login, owner, slug] }
    end

    def listed_confirmed(logins, teams)
      result = empty_result
      teams.each do |owner, slug|
        unresolved = logins.reject { |login| result[:trusted].include?(login) }
        break if unresolved.empty?

        confirmed(team_candidates(unresolved, owner, slug), result)
      end
      result
    rescue Error => e
      raise Error, "Team-member list evidence is unavailable: #{e.message}"
    end

    def team_candidates(logins, owner, slug)
      members = listed_members(owner, slug)
      logins.filter_map { |login| [login, owner, slug] if members.include?(login) }
    rescue BoundedList::LimitError
      fallback_pairs(logins, owner, slug)
    end

    def fallback_pairs(logins, owner, slug)
      @fallback_count += logins.length
      raise Error, 'Direct team fallback exceeds 100 checks.' if @fallback_count > MAX_FALLBACK_PAIRS

      logins.map { |login| [login, owner, slug] }
    end

    def listed_members(owner, slug)
      path = "orgs/#{owner}/teams/#{slug}/members"
      BoundedList.new(@github, max_pages: MAX_TEAM_PAGES, label: 'Team-member list')
                 .call(path).filter_map { |member| member_login(member) }.to_set
    end

    def member_login(member)
      login = member['login']
      login.downcase if member['type'] == 'User' && login.is_a?(String) && login.match?(GitHubLogin::PATTERN)
    end

    def membership_state(owner, slug, login)
      result = @github.api("orgs/#{owner}/teams/#{slug}/memberships/#{login}")
      url = result['url']
      state = result['state']
      return nil unless %w[active pending].include?(state) && url.is_a?(String) &&
                        url.downcase.end_with?("/memberships/#{login.downcase}")

      state == 'active'
    rescue Error => e
      return false if e.http_status == 404 && team_members_readable?(owner, slug)

      nil
    end

    def team_members_readable?(owner, slug)
      key = [owner, slug]
      return @readable_teams[key] if @readable_teams.key?(key)

      path = "orgs/#{owner}/teams/#{slug}/members?per_page=1&page=1"
      @readable_teams[key] = @github.api_list(path).all?(Hash)
    rescue Error
      @readable_teams[key] = false
    end
  end
end
