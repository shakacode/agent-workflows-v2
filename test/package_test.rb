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
    run_gem('build', 'agent-workflows-v2.gemspec', '--output', archive, chdir: ROOT)
    run_gem('install', '--local', '--no-document', archive)
    assert_includes run_executable('aw', '--help'), 'Usage: aw'
    source = install_skill
    File.unlink(File.join(@directory, 'pilot skills', 'aw'))
    run_gem('uninstall', 'agent-workflows-v2', '--all', '--executables', '--ignore-dependencies')
    refute File.exist?(File.join(@home, 'bin', 'aw'))
    refute File.exist?(source)
  end

  private

  def install_skill
    skills = File.join(@directory, 'pilot skills')
    run_executable('install-agent-workflows', '--skills-dir', skills)
    source = File.realpath(File.join(skills, 'aw'))
    assert source.start_with?("#{File.realpath(@home)}/gems/"), source
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
