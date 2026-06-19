require "ith_growth/article/parser"
require "ith_growth/workflows/base_workflow"

module IthGrowth
  module Workflows
    class SeoWorkflow < BaseWorkflow
      def run(path, website_repo: nil)
        article = Article::Parser.new.parse(path)
        with_logging(name: "seo", input_files: [path, website_repo].compact) do
          markdown = prompt_runner.run(
            template: "seo",
            variables: common_variables(article).merge(website_repo: website_repo),
            model: config.ai_model
          )
          schema = {
            "@context": "https://schema.org",
            "@type": "Article",
            "headline": article.title,
            "url": "{{ARTICLE_URL}}",
            "description": "Replace with generated meta description from seo.md"
          }
          [
            writer.write("articles/#{article.slug}/seo.md", markdown),
            writer.write_json("articles/#{article.slug}/schema.json", schema)
          ]
        end
      end
    end
  end
end
