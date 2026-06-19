require "fileutils"
require "json"
require "date"
require "time"

module IthGrowth
  class Logger
    def initialize(output_dir:)
      @output_dir = output_dir
    end

    def log(event)
      FileUtils.mkdir_p(log_dir)
      File.open(log_path, "a") do |file|
        file.puts(JSON.generate({ timestamp: Time.now.utc.iso8601 }.merge(event)))
      end
    end

    def log_path
      File.join(log_dir, "#{Date.today}.log")
    end

    private

    def log_dir
      File.join(@output_dir, "logs")
    end
  end
end
