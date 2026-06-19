module IthGrowth
  module AI
    class PromptRunner
      PROMPT_DIR = File.expand_path("../prompts", __dir__)

      attr_reader :client

      def initialize(client:)
        @client = client
      end

      def run(template:, variables:, system: nil, model: nil, temperature: 0.4)
        prompt = render(template: template, variables: variables)
        client.complete(prompt: prompt, system: system, model: model, temperature: temperature)
      end

      def render(template:, variables:)
        text = File.read(File.join(PROMPT_DIR, "#{template}.md"))
        variables.reduce(text) do |rendered, (key, value)|
          rendered.gsub("{{#{key}}}", value.to_s)
        end
      end
    end
  end
end
