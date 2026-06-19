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
        with_logging(name: "distribution", input_files: [path]) do
          PLATFORMS.map do |platform|
            markdown = prompt_runner.run(
              template: "distribution",
              variables: common_variables(article).merge(platform: platform),
              model: config.ai_model
            )
            writer.write("articles/#{article.slug}/distribution/#{platform}.md", markdown)
          end
        end
      end
    end
  end
end
