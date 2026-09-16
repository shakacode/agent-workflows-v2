# frozen_string_literal: true

require_relative 'test_helper'

class CliTest < Minitest::Test
  COMMAND = File.expand_path('../skills/shaka/scripts/shaka', __dir__)

  def test_help_explains_each_operation
    output, error, status = Open3.capture3(COMMAND, '--help')
    assert status.success?, error
    %w[pr description reply walkthrough merge --head --content-file --key].each do |token|
      assert_includes output, token
    end
  end

  def test_missing_content_file_is_a_clear_error
    _output, error, status = Open3.capture3(COMMAND, 'description', 'owner/repo', '1',
                                            '--content-file', '/missing/shaka-content.json')
    refute status.success?
    assert_includes error, 'shaka-content.json'
  end

  def test_a_reply_without_a_key_does_not_call_github
    _output, error, status = Open3.capture3(COMMAND, 'reply', 'owner/repo', '1',
                                            '--content-file', '/missing/shaka-content.json')
    refute status.success?
    assert_includes error, 'shaka:'
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
end
