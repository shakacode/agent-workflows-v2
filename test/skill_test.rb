# frozen_string_literal: true

require_relative 'test_helper'

class SkillTest < Minitest::Test
  SKILL = File.read(File.expand_path('../skills/shaka/SKILL.md', __dir__))
  CHECKPOINT = SKILL[/After reading the task.*?Work solo/m]
  EFFORT_LEVELS = %w[minimal low medium high xhigh max ultra].freeze

  def test_model_checkpoint_assesses_the_task_before_selecting_settings
    refute_nil CHECKPOINT

    assert_before 'scope', 'model'
    assert_before 'risk', 'model'
    assert_before 'risk', 'effort'

    EFFORT_LEVELS.each do |level|
      refute_match(/\b#{level} effort\b/i, CHECKPOINT)
    end
  end

  def test_model_checkpoint_explains_the_relevant_cost_tradeoff
    assert_match(/effort.*not priced per token/i, CHECKPOINT)
    assert_match(/input.*dominates.*spend/i, CHECKPOINT)
    assert_match(/avoid.*rework/i, CHECKPOINT)
    assert_match(/#45/, CHECKPOINT)
  end

  private

  def assert_before(first, second)
    positions = [first, second].to_h { |concept| [concept, CHECKPOINT.index(concept)] }
    assert positions.values.all?, positions.inspect
    assert_operator positions.fetch(first), :<, positions.fetch(second)
  end
end
