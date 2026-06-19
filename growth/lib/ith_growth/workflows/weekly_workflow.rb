require "date"
require "ith_growth/workflows/base_workflow"
require "ith_growth/analytics/ga_client"

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
              generated_outputs: content,
              traffic_data: fetch_traffic_data
            },
            model: config.ai_model
          )
          [writer.write("reports/weekly/#{Date.today.cwyear}-#{format('%02d', Date.today.cweek)}.md", report)]
        end
      end

      private

      def fetch_traffic_data
        return "_Analytics not configured._" unless config.ga4_property_id && config.ga4_credentials_path

        client = Analytics::GaClient.new(
          property_id: config.ga4_property_id,
          credentials_path: config.ga4_credentials_path
        )
        client.format_as_markdown(client.top_pages(days: 7, limit: 20))
      rescue => e
        "_Analytics unavailable: #{e.message}_"
      end

      def recent_output_files
        since = Time.now - (7 * 24 * 60 * 60)
        Dir.glob(File.join(config.output_dir, "articles/**/*.{md,json}")).select { |path| File.mtime(path) >= since }
      end
    end
  end
end
