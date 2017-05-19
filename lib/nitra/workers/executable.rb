require 'open3'

module Nitra::Workers
  class Executable < Worker
    PRINT_OUTPUT = true
    FAIL_WITH_RESULT = false
    SUCCESS_ON_NO_RUN = true

    def self.filename_match?(filename)
      filename =~ /\w+/ # TODO match against no extension or files within "bin"?
    end

    def initialize(runner_id, worker_number, configuration)
      super(runner_id, worker_number, configuration)
    end

    def load_environment; end

    def minimal_file
      <<-EOS
      #!/usr/bin/env ruby
      puts "Hello, World!"
      EOS
    end

    ##
    # Run an executable file
    #
    def run_file(filename, preloading = false)
      result = execute(filename) if File.exist?(filename) && File.executable?(filename)

      {
        "test_count"    => 0,
        "failure_count" => 0,
        "failure"       => FAIL_WITH_RESULT && !success?(filename, result),
        "info"          => PRINT_OUTPUT,
      }
    end

    def clean_up
      super
    end

    private

    def execute(filename)
      Open3.popen2e("./#{filename}") do |stdin, stdout_err, wait_thr|
        while line = stdout_err.gets
          io << line
        end

        wait_thr.value
      end
    end

    def success?(filename, result)
      if nitra_warm_up_file?(filename)
        debug "Skipped nitra warm up file"
      elsif result.nil?
        debug "File #{filename} could not be executed"
      end

      result.nil? ? SUCCESS_ON_NO_RUN : execution_success?(result)
    end

    def execution_success?(result)
      result.exited? && result.success?
    end

    def nitra_warm_up_file?(filename)
      !!(filename =~ /\/nitra.+/)
    end
  end
end
