# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = 'agent-workflows-v2'
  spec.version = '0.1.0.pre.1'
  spec.summary = 'A small, portable workflow for one agent and one pull request'
  spec.authors = ['ShakaCode']
  spec.homepage = 'https://github.com/shakacode/agent-workflows-v2'
  spec.required_ruby_version = '>= 3.4'
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.metadata['documentation_uri'] = "#{spec.homepage}/blob/main/docs/getting-started.md"
  spec.files = Dir['skills/aw/SKILL.md', 'skills/aw/lib/**/*.rb',
                   'skills/aw/scripts/*', 'bin/install', 'exe/*', 'docs/*.md', 'README.md']
  spec.bindir = 'exe'
  spec.executables = %w[aw install-agent-workflows]
  spec.require_paths = ['skills/aw/lib']
end
