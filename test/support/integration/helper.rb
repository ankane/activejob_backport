puts "\n\n"
puts "*** Running integration tests for #{ENV['AJADAPTER']} ***"
puts "\n\n"

ENV["RAILS_ENV"] = "test"
ActiveJob::Base.queue_name_prefix = nil

require 'rails/generators'
require 'rails/generators/rails/app/app_generator'

if !defined?(Rails::Generators::ARGVScrubber)
  # This class handles preparation of the arguments before the AppGenerator is
  # called. The class provides version or help information if they were
  # requested, and also constructs the railsrc file (used for extra configuration
  # options).
  #
  # This class should be called before the AppGenerator is required and started
  # since it configures and mutates ARGV correctly.
  class Rails::Generators::ARGVScrubber
    def initialize(argv = ARGV)
      @argv = argv
    end

    def prepare!
      handle_version_request!(@argv.first)
      handle_invalid_command!(@argv.first, @argv) do
        handle_rails_rc!(@argv.drop(1))
      end
    end

    def self.default_rc_file
      File.expand_path('~/.railsrc')
    end

    private

      def handle_version_request!(argument)
        if ['--version', '-v'].include?(argument)
          require 'rails/version'
          puts "Rails #{Rails::VERSION::STRING}"
          exit(0)
        end
      end

      def handle_invalid_command!(argument, argv)
        if argument == "new"
          yield
        else
          ['--help'] + argv.drop(1)
        end
      end

      def handle_rails_rc!(argv)
        if argv.find { |arg| arg == '--no-rc' }
          argv.reject { |arg| arg == '--no-rc' }
        else
          railsrc(argv) { |rc_argv, rc| insert_railsrc_into_argv!(rc_argv, rc) }
        end
      end

      def railsrc(argv)
        if (customrc = argv.index{ |x| x.include?("--rc=") })
          fname = File.expand_path(argv[customrc].gsub(/--rc=/, ""))
          yield(argv.take(customrc) + argv.drop(customrc + 1), fname)
        else
          yield argv, self.class.default_rc_file
        end
      end

      def read_rc_file(railsrc)
        extra_args = File.readlines(railsrc).flat_map(&:split)
        puts "Using #{extra_args.join(" ")} from #{railsrc}"
        extra_args
      end

      def insert_railsrc_into_argv!(argv, railsrc)
        return argv unless File.exist?(railsrc)
        extra_args = read_rc_file railsrc
        argv.take(1) + extra_args + argv.drop(1)
      end
  end
end

dummy_app_path     = Dir.mktmpdir + "/dummy"
dummy_app_template = File.expand_path("../dummy_app_template.rb",  __FILE__)
args = Rails::Generators::ARGVScrubber.new(["new", dummy_app_path, "--skip-gemfile", "--skip-bundle",
  "--skip-git", "--skip-spring", "-d", "sqlite3", "--skip-javascript", "--force", "--quite",
  "--template", dummy_app_template]).prepare!
Rails::Generators::AppGenerator.start args

require "#{dummy_app_path}/config/environment.rb"

ActiveRecord::Migrator.migrations_paths = [ Rails.root.join('db/migrate').to_s ]
require 'rails/test_help'

Rails.backtrace_cleaner.remove_silencers!

require_relative 'test_case_helpers'
ActiveSupport::TestCase.send(:include, TestCaseHelpers)

JobsManager.current_manager.start_workers

if Minitest.respond_to?(:after_run)
  Minitest.after_run do
    JobsManager.current_manager.stop_workers
    JobsManager.current_manager.clear_jobs
  end
else
  MiniTest::Unit.after_tests do
    JobsManager.current_manager.stop_workers
    JobsManager.current_manager.clear_jobs
  end
end
