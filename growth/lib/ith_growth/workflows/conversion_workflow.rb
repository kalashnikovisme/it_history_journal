require "ith_growth/article/parser"
require "ith_growth/workflows/base_workflow"

module IthGrowth
  module Workflows
    class ConversionWorkflow < BaseWorkflow
      def run(path)
        article = Article::Parser.new.parse(path)
        with_logging(name: "conversion", input_files: [path]) do
          markdown = prompt_runner.run(
            template: "conversion",
            variables: common_variables(article),
            model: config.ai_model
          )
          [writer.write("articles/#{article.slug}/conversion.md", markdown)]
        end
      end
    end
  end
end
