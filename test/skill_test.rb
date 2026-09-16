# frozen_string_literal: true

require_relative 'test_helper'

class SkillTest < Minitest::Test
  def test_public_skill_stays_within_the_context_budget
    skill = File.expand_path('../skills/shaka/SKILL.md', __dir__)
    # Issue #33 sets the public skill's 6 KiB context budget.
    assert_operator File.size(skill), :<=, 6 * 1024
  end
end
