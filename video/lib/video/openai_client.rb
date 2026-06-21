require "openai"

module Video
  class OpenAIClient
    def initialize(api_key: ENV["OPENAI_API_KEY"])
      if api_key.to_s.strip.empty?
        raise "OPENAI_API_KEY is not set. Export it in your environment or add it to .env.dev."
      end

      @client = OpenAI::Client.new(access_token: api_key)
    end

    # Returns the assistant's reply as a String.
    def chat(messages:, model: "gpt-4.1", temperature: 0.7)
      response = @client.chat(
        parameters: {
          model:       model,
          messages:    messages,
          temperature: temperature
        }
      )
      response.dig("choices", 0, "message", "content") ||
        raise("OpenAI chat returned no content: #{response.inspect}")
    end

    # Calls TTS and writes MP3 bytes to output_path.
    def tts(text:, voice: "onyx", model: "tts-1-hd", output_path:)
      response = @client.audio.speech(
        parameters: {
          model:  model,
          input:  text,
          voice:  voice,
          response_format: "mp3"
        }
      )
      File.binwrite(output_path, response)
    end
  end
end
