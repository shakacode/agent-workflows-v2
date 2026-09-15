# frozen_string_literal: true

require_relative 'test_helper'

class CliTest < Minitest::Test
  COMMAND = File.expand_path('../skills/sw/scripts/sw', __dir__)

  def test_help_explains_the_three_operations
    output, error, status = Open3.capture3(COMMAND, '--help')
    assert status.success?, error
    assert_includes output, 'pr|walkthrough|merge'
    assert_includes output, '--head'
  end

  def test_invalid_operation_exits_without_a_github_call
    _output, error, status = Open3.capture3(COMMAND, 'unexpected', 'owner/repo', '1')
    refute status.success?
    assert_includes error, 'Usage:'
  end

  def test_missing_walkthrough_file_is_a_clear_error
    _output, error, status = Open3.capture3(COMMAND, 'walkthrough', 'owner/repo', '1',
                                            '--head', 'a' * 40, '--body-file', '/missing/sw-v2-body.md')
    refute status.success?
    assert_includes error, 'sw:'
    assert_includes error, 'sw-v2-body.md'
  end

  def test_merge_without_head_does_not_call_github
    _output, error, status = Open3.capture3(COMMAND, 'merge', 'owner/repo', '1')
    refute status.success?
    assert_includes error, 'head'
  end
end
