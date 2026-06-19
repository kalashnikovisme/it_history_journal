require "date"
require "ith_growth/workflows/base_workflow"

module IthGrowth
  module Workflows
    class WeeklyWorkflow < BaseWorkflow
      def run
        with_logging(name: "weekly", input_files: recent_output_files) do
          content = recent_output_files.map { |path| "## #{path}\n\n#{File.read(path)}" }.join("\n\n")
          report = prompt_runner.run(
            template: "weekly_report",
            variables: {
              project_name: config.dig(:project, :name),
              generated_outputs: content
            },
            model: config.ai_model
          )
          [writer.write("reports/weekly/#{Date.today.cwyear}-#{format('%02d', Date.today.cweek)}.md", report)]
        end
      end

      private

      def recent_output_files
        since = Time.now - (7 * 24 * 60 * 60)
        Dir.glob(File.join(config.output_dir, "articles/**/*.{md,json}")).select { |path| File.mtime(path) >= since }
      end
    end
  end
end
