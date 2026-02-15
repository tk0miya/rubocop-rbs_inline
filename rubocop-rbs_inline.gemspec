# frozen_string_literal: true

require_relative 'lib/rubocop/rbs_inline/version'

Gem::Specification.new do |spec|
  spec.name = 'rubocop-rbs_inline'
  spec.version = RuboCop::RbsInline::VERSION
  spec.authors = ['Takeshi KOMIYA']
  spec.email = ['i.tkomiya@gmail.com']

  spec.summary = 'rubocop extension to check RBS annotation comments'
  spec.description = 'rubocop extension to check RBS annotation comments'
  spec.homepage = 'https://github.com/tk0miya/rubocop-rbs_inline'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.3.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = spec.homepage

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'lint_roller', '~> 1.1'
  spec.add_dependency 'rbs-inline'
  spec.add_dependency 'rubocop', '>= 1.72.1', '< 2.0'
  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.metadata['default_lint_roller_plugin'] = 'RuboCop::RbsInline::Plugin'
end
