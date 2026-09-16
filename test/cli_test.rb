# frozen_string_literal: true

require_relative 'test_helper'

class CliTest < Minitest::Test
  COMMAND = File.expand_path('../skills/shaka/scripts/shaka', __dir__)

  def test_help_explains_the_operations
    output, error, status = Open3.capture3(COMMAND, '--help')
    assert status.success?, error
    assert_includes output, 'pr|comments|walkthrough|merge'
    assert_includes output, '--head'
    assert_includes output, '--issue'
  end

  def test_invalid_operation_exits_without_a_github_call
    _output, error, status = Open3.capture3(COMMAND, 'unexpected', 'owner/repo', '1')
    refute status.success?
    assert_includes error, 'Usage:'
  end

  def test_missing_walkthrough_file_is_a_clear_error
    _output, error, status = Open3.capture3(COMMAND, 'walkthrough', 'owner/repo', '1',
                                            '--head', 'a' * 40, '--body-file', '/missing/shaka-body.md')
    refute status.success?
    assert_includes error, 'shaka:'
    assert_includes error, 'shaka-body.md'
  end

  def test_merge_without_head_does_not_call_github
    _output, error, status = Open3.capture3(COMMAND, 'merge', 'owner/repo', '1')
    refute status.success?
    assert_includes error, 'head'
  end

  def test_pr_comment_reader_requires_an_expected_head
    _output, error, status = Open3.capture3(COMMAND, 'comments', 'owner/repo', '1')
    refute status.success?
    assert_includes error, 'Expected a full PR head'
  end
end
