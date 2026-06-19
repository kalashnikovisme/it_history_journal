require "anthropic"
require "ith_growth/ai/client"

module IthGrowth
  module AI
    class AnthropicClient < Client
      def initialize(api_key: ENV["ANTHROPIC_API_KEY"])
        raise MissingApiKey, "ANTHROPIC_API_KEY is required for the Anthropic provider" if api_key.to_s.empty?

        @client = Anthropic::Client.new(access_token: api_key)
      end

      def complete(prompt:, system: nil, model: nil, temperature: 0.4)
        response = @client.messages(
          parameters: {
            model: model || "claude-sonnet-4-20250514",
            max_tokens: 4000,
            temperature: temperature,
            system: system,
            messages: [{ role: "user", content: prompt }]
          }.compact
        )
        Array(response["content"]).map { |part| part["text"] }.join
      end

      def provider
        "anthropic"
      end

      class MissingApiKey < StandardError; end
    end
  end
end
