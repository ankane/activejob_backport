require 'bundler/gem_tasks'
require 'rake/testtask'

ACTIVEJOB_ADAPTERS = %w(inline delayed_job qu que queue_classic resque sidekiq sneakers sucker_punch backburner test)
ACTIVEJOB_ADAPTERS -= %w(queue_classic) if defined?(JRUBY_VERSION)

task default: :test
task test: 'test:default'

namespace :test do
  desc 'Run all adapter tests'
  task :default do
    run_without_aborting ACTIVEJOB_ADAPTERS.map { |a| "test:#{a}" }
  end

  desc 'Run all adapter tests in isolation'
  task :isolated do
    run_without_aborting ACTIVEJOB_ADAPTERS.map { |a| "test:isolated:#{a}" }
  end

  desc 'Run integration tests for all adapters'
  task :integration do
    run_without_aborting (ACTIVEJOB_ADAPTERS - ['test']).map { |a| "test:integration:#{a}" }
  end

  task 'env:integration' do
    ENV['AJ_INTEGRATION_TESTS'] = "1"
  end

  ACTIVEJOB_ADAPTERS.each do |adapter|
    task("env:#{adapter}") { ENV['AJADAPTER'] = adapter }

    Rake::TestTask.new(adapter => "test:env:#{adapter}") do |t|
      t.description = "Run adapter tests for #{adapter}"
      t.libs << 'test'
      t.test_files = FileList['test/cases/**/*_test.rb']
      t.verbose = true
      t.warning = true
      t.ruby_opts = ["--dev"] if defined?(JRUBY_VERSION)
    end

    namespace :isolated do
      task adapter => "test:env:#{adapter}" do
        dir = File.dirname(__FILE__)
        Dir.glob("#{dir}/test/cases/**/*_test.rb").all? do |file|
          sh(Gem.ruby, '-w', "-I#{dir}/lib", "-I#{dir}/test", file)
        end or raise 'Failures'
      end
    end

    namespace :integration do
      Rake::TestTask.new(adapter => ["test:env:#{adapter}", 'test:env:integration']) do |t|
        t.description = "Run integration tests for #{adapter}"
        t.libs << 'test'
        t.test_files = FileList['test/integration/**/*_test.rb']
        t.verbose = true
        t.warning = true
        t.ruby_opts = ["--dev"] if defined?(JRUBY_VERSION)
      end
    end
  end
end

def run_without_aborting(tasks)
  errors = []

  tasks.each do |task|
    begin
      Rake::Task[task].invoke
    rescue Exception
      errors << task
    end
  end

  abort "Errors running #{errors.join(', ')}" if errors.any?
end
