# frozen_string_literal: true

require_relative 'test_helper'
require 'fileutils'
require 'rbconfig'
require 'bundler'

class PackageTest < Minitest::Test
  ROOT = File.expand_path('..', __dir__)

  def setup
    @directory = Dir.mktmpdir('workflows-package')
    @home = File.join(@directory, 'gem home')
    @environment = { 'GEM_HOME' => @home, 'GEM_PATH' => @home }
  end

  def teardown
    FileUtils.remove_entry(@directory)
  end

  def test_built_gem_runs_and_installs_its_skill_without_the_source_checkout
    archive = File.join(@directory, 'pilot.gem')
    run_gem('build', 'shakacode-workflows.gemspec', '--output', archive, chdir: ROOT)
    run_gem('install', '--local', '--no-document', archive)
    check_commands
    source = install_skill
    %w[sw aw].each { |name| File.unlink(File.join(@directory, 'pilot skills', name)) }
    run_gem('uninstall', 'shakacode-workflows', '--all', '--executables', '--ignore-dependencies')
    refute File.exist?(File.join(@home, 'bin', 'aw'))
    refute File.exist?(source)
  end

  private

  def check_commands
    %w[sw aw].each { |name| assert_includes run_executable(name, '--help'), 'Usage: sw' }
  end

  def check_public_skill(skills, source)
    sw = File.realpath(File.join(skills, 'sw'))
    assert File.file?(File.join(sw, 'SKILL.md'))
    assert_equal source, File.realpath(File.join(sw, '..', 'aw'))
  end

  def install_skill
    skills = File.join(@directory, 'pilot skills')
    run_executable('install-agent-workflows', '--skills-dir', skills)
    source = File.realpath(File.join(skills, 'aw'))
    assert source.start_with?("#{File.realpath(@home)}/gems/"), source
    check_public_skill(skills, source)
    assert File.file?(File.join(source, 'SKILL.md'))
    assert File.file?(File.join(source, 'scripts', 'aw'))
    source
  end

  def run_executable(name, *)
    run_command(File.join(@home, 'bin', name), *)
  end

  def run_gem(*, chdir: @directory)
    run_command('-S', 'gem', *, chdir: chdir)
  end

  def run_command(*, chdir: @directory)
    output, status = Bundler.with_unbundled_env do
      Open3.capture2e(@environment, RbConfig.ruby, *, chdir: chdir)
    end
    assert status.success?, output
    output
  end
end
