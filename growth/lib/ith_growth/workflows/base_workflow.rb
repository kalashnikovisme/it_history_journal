require "json"
require "time"
require "colorize"

module IthGrowth
  module Workflows
    class BaseWorkflow
      attr_reader :config, :prompt_runner, :writer, :logger

      def initialize(config:, prompt_runner:, writer:, logger:)
        @config = config
        @prompt_runner = prompt_runner
        @writer = writer
        @logger = logger
      end

      private

      def with_logging(name:, input_files: [])
        $stdout.puts "▶ #{name}".yellow.bold
        started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        output_files = yield
        elapsed_s = elapsed(started)
        $stdout.puts "  ✓ done in #{elapsed_s}s".green
        output_files.each { |f| $stdout.puts "    #{f}".cyan }
        logger.log(
          command: $PROGRAM_NAME,
          workflow: name,
          input_files: input_files,
          output_files: output_files,
          ai_provider: prompt_runner.client.provider,
          model: config.ai_model,
          duration_seconds: elapsed_s
        )
        output_files
      rescue StandardError => e
        $stdout.puts "  ✗ #{e.class}: #{e.message}".red
        logger.log(
          command: $PROGRAM_NAME,
          workflow: name,
          input_files: input_files,
          output_files: [],
          ai_provider: prompt_runner.client.provider,
          model: config.ai_model,
          duration_seconds: elapsed(started),
          error: "#{e.class}: #{e.message}"
        )
        raise
      end

      def elapsed(started)
        (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started).round(3)
      end

      def common_variables(article)
        {
          project_name: config.dig(:project, :name),
          site_url: config.site_url,
          patreon_url: config.dig(:growth, :patreon_url),
          boosty_url: config.dig(:growth, :boosty_url),
          article_title: article.title,
          article_body: article.body,
          article_slug: article.slug,
          article_url: "{{ARTICLE_URL}}"
        }
      end
    end
  end
end
