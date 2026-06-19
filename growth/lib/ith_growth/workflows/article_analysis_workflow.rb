require "ith_growth/article/parser"
require "ith_growth/article/slugger"
require "ith_growth/workflows/base_workflow"

module IthGrowth
  module Workflows
    class ArticleAnalysisWorkflow < BaseWorkflow
      def run(path)
        article = Article::Parser.new.parse(path)
        with_logging(name: "article_analysis", input_files: [path]) do
          markdown = prompt_runner.run(
            template: "article_analysis",
            variables: common_variables(article),
            model: config.ai_model
          )
          json = {
            title: article.title,
            slug: article.slug,
            source_path: path,
            generated_at: Time.now.utc.iso8601,
            analysis_markdown: markdown
          }
          [
            writer.write("articles/#{article.slug}/analysis.md", markdown),
            writer.write_json("articles/#{article.slug}/analysis.json", json)
          ]
        end
      end
    end
  end
end
