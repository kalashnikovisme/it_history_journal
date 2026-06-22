require "json"
require "net/http"

module Video
  class TelegramNotifier
    DEFAULT_CHAT_ID = "@kalashnikovisme"

    def self.configured?
      !ENV["TELEGRAM_BOT_TOKEN"].to_s.empty?
    end

    def initialize(
      token: ENV["TELEGRAM_BOT_TOKEN"],
      chat_id: ENV.fetch("TELEGRAM_CHAT_ID", DEFAULT_CHAT_ID)
    )
      raise "TELEGRAM_BOT_TOKEN is not set" if token.to_s.empty?

      @token = token
      @chat_id = chat_id
    end

    def deliver(video_path, youtube)
      File.open(video_path, "rb") do |video|
        post("sendVideo", chat_id: @chat_id, video: video)
      end
      post("sendMessage", chat_id: @chat_id, text: youtube.fetch("title"))
      post("sendMessage", chat_id: @chat_id, text: youtube.fetch("description"))
      post("sendMessage", chat_id: @chat_id, text: youtube.fetch("tags").join(", "))
    end

    private

    def post(method, fields)
      uri = URI("https://api.telegram.org/bot#{@token}/#{method}")
      request = Net::HTTP::Post.new(uri)
      request.set_form(fields.to_a, "multipart/form-data")
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(request)
      end
      payload = JSON.parse(response.body)
      return payload.fetch("result") if response.is_a?(Net::HTTPSuccess) && payload["ok"]

      raise "Telegram #{method} failed: #{payload['description'] || response.message}"
    rescue JSON::ParserError
      raise "Telegram #{method} returned an invalid response (HTTP #{response.code})"
    end
  end
end
