# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rubocop/rake_task'

RuboCop::RakeTask.new

task default: :ci

task ci: %i[rubocop spec steep rbs:validate]

require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

desc 'Generate a new cop with a template'
task :new_cop, [:cop] do |_task, args|
  require 'rubocop'

  cop_name = args.fetch(:cop) do
    warn 'usage: bundle exec rake new_cop[Department/Name]'
    exit!
  end

  generator = RuboCop::Cop::Generator.new(cop_name)

  generator.write_source
  generator.write_spec
  generator.inject_require(root_file_path: 'lib/rubocop/cop/rbs_inline_cops.rb')
  generator.inject_config(config_file_path: 'config/default.yml')

  puts generator.todo
end

namespace :rbs do
  desc 'Install RBS signatures'
  task :install do
    sh 'bundle', 'exec', 'rbs', 'collection', 'install', '--frozen'
  end

  desc 'Generate RBS files'
  task :generate do
    sh 'rbs-inline', '--opt-out', '--output=sig', 'lib'
  end

  desc 'Validate RBS files'
  task validate: 'rbs:install' do
    sh 'rbs', '-Isig', 'validate'
  end
end

desc 'Run Steep type checker'
task steep: 'rbs:install' do
  sh 'bundle', 'exec', 'steep', 'check'
end
