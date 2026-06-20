require "ith_growth/article/parser"
require "ith_growth/workflows/base_workflow"

module IthGrowth
  module Workflows
    class DistributionWorkflow < BaseWorkflow
      PLATFORMS = %w[
        twitter twitter_thread telegram linkedin reddit hacker_news lobsters
        bluesky devto medium youtube_shorts tiktok
      ].freeze

      def run(path)
        article = Article::Parser.new.parse(path)
        article_rel_dir = article_relative_dir(article.path)
        dist_writer = Outputs::Writer.new(base_dir: config.distribution_output_dir)
        with_logging(name: "distribution", input_files: [path]) do
          PLATFORMS.map do |platform|
            markdown = prompt_runner.run(
              template: "distribution",
              variables: common_variables(article).merge(platform: platform),
              model: config.ai_model
            )
            dist_writer.write("articles/#{article_rel_dir}/#{platform}.md", markdown)
          end
        end
      end

    end
  end
end
