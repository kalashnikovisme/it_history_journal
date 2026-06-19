require "date"
require "ith_growth/workflows/article_analysis_workflow"
require "ith_growth/workflows/distribution_workflow"
require "ith_growth/workflows/seo_workflow"
require "ith_growth/workflows/conversion_workflow"

module IthGrowth
  module Workflows
    class DailyWorkflow < BaseWorkflow
      def run
        article_paths = recent_articles
        with_logging(name: "daily", input_files: article_paths) do
          outputs = article_paths.flat_map do |path|
            ArticleAnalysisWorkflow.new(config: config, prompt_runner: prompt_runner, writer: writer, logger: logger).run(path) +
              DistributionWorkflow.new(config: config, prompt_runner: prompt_runner, writer: writer, logger: logger).run(path) +
              SeoWorkflow.new(config: config, prompt_runner: prompt_runner, writer: writer, logger: logger).run(path) +
              ConversionWorkflow.new(config: config, prompt_runner: prompt_runner, writer: writer, logger: logger).run(path)
          end
          report = <<~MD
            # Daily Growth Report - #{Date.today}

            Articles processed: #{article_paths.size}

            ## Source Articles

            #{article_paths.map { |path| "- #{path}" }.join("\n")}

            ## Generated Outputs

            #{outputs.map { |path| "- #{path}" }.join("\n")}
          MD
          [writer.write("reports/daily/#{Date.today}.md", report)]
        end
      end

      private

      def recent_articles
        dir = config.content_dir
        return [] unless dir && Dir.exist?(dir)

        since = Time.now - (24 * 60 * 60)
        Dir.glob(File.join(dir, "**/*.md")).select { |path| File.mtime(path) >= since }
      end
    end
  end
end
