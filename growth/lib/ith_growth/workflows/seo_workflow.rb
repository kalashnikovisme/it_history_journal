require "json"
require "ith_growth/article/parser"
require "ith_growth/article/patcher"
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

          patch = extract_patch(markdown)
          clean_markdown = strip_patch_block(markdown)

          schema = {
            "@context": "https://schema.org",
            "@type": "Article",
            "headline": patch["title"] || article.title,
            "url": "{{ARTICLE_URL}}",
            "description": patch["excerpt"] || ""
          }

          outputs = [
            writer.write("articles/#{article.slug}/seo.md", clean_markdown),
            writer.write_json("articles/#{article.slug}/schema.json", schema)
          ]

          if patch.any?
            writer.write_json("articles/#{article.slug}/seo_patch.json", patch)
            Article::Patcher.new.apply(path, patch)
          end

          outputs
        end
      end

      private

      def extract_patch(markdown)
        # Try explicit seo_patch tag first, then fall back to any JSON block
        # that contains title+excerpt (model sometimes uses ```json instead).
        blocks = markdown.scan(/```(?:seo_patch|json)?\n(.*?)\n```/m).map(&:first)
        blocks.reverse_each do |json|
          data = JSON.parse(json).slice("title", "excerpt")
          return data if data.any?
        rescue JSON::ParserError
          next
        end
        {}
      end

      def strip_patch_block(markdown)
        markdown.gsub(/```seo_patch\n.*?\n```\n?/m, "").strip
      end
    end
  end
end
