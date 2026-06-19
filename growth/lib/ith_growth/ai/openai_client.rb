require "openai"
require "ith_growth/ai/client"

module IthGrowth
  module AI
    class OpenaiClient < Client
      def initialize(api_key: ENV["OPENAI_API_KEY"])
        raise MissingApiKey, "OPENAI_API_KEY is required for the OpenAI provider" if api_key.to_s.empty?

        @client = OpenAI::Client.new(access_token: api_key)
      end

      def complete(prompt:, system: nil, model: nil, temperature: 0.4)
        messages = []
        messages << { role: "system", content: system } if system
        messages << { role: "user", content: prompt }

        response = @client.chat(
          parameters: {
            model: model || "gpt-4.1-mini",
            messages: messages,
            temperature: temperature
          }
        )
        response.dig("choices", 0, "message", "content").to_s
      end

      def provider
        "openai"
      end

      class MissingApiKey < StandardError; end
    end
  end
end
