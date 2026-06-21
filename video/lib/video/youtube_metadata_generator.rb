require "json"

module Video
  class YoutubeMetadataGenerator
    TITLE_MAX_LENGTH = 100
    DESCRIPTION_MAX_BYTES = 5_000
    TAGS_MAX_LENGTH = 500
    TAG_COUNT_RANGE = (5..15)

    def initialize(article_info, output_paths, openai_client)
      @info = article_info
      @paths = output_paths
      @client = openai_client
    end

    def generate(narration, force: false)
      @paths.ensure_dir!
      metadata = load_metadata
      return [metadata.fetch("youtube"), true] if metadata["youtube"] && !force

      response = @client.chat(
        messages: [
          { role: "system", content: system_prompt },
          { role: "user", content: build_prompt(narration) }
        ],
        model: "gpt-4.1",
        temperature: 0.6
      )

      youtube = validate(JSON.parse(strip_code_fence(response)))
      File.write(@paths.metadata_json, JSON.pretty_generate(metadata.merge("youtube" => youtube)))
      [youtube, false]
    rescue JSON::ParserError => e
      raise "YouTube metadata response is not valid JSON: #{e.message}"
    end

    private

    def load_metadata
      return stringify_keys(@info) unless File.exist?(@paths.metadata_json)

      JSON.parse(File.read(@paths.metadata_json))
    end

    def system_prompt
      <<~PROMPT.strip
        You are a YouTube Shorts editor for IT History Journal. Create accurate, compelling
        packaging that maximizes qualified discovery and viewing intent without clickbait.
        Return only a valid JSON object with exactly these keys: title, description, tags.
      PROMPT
    end

    def build_prompt(narration)
      language = @info[:lang] == "ru" ? "Russian" : "English"

      <<~PROMPT.strip
        Create the best YouTube Shorts metadata in #{language} for this video.

        Article title: #{@info[:title]}
        Date: #{@info[:date_display]}

        Narration:
        #{narration}

        Article content:
        #{@info[:content_md]}

        Requirements:
        - title: specific, natural, curiosity-driven, factually accurate, at most #{TITLE_MAX_LENGTH} characters
        - description: at most #{DESCRIPTION_MAX_BYTES} bytes; concise summary with useful search context, a soft IT History Journal CTA, and up to 3 relevant hashtags including #Shorts
        - tags: JSON array of #{TAG_COUNT_RANGE.begin}-#{TAG_COUNT_RANGE.end} distinct search tags without # prefixes; keep the combined YouTube tag length under #{TAGS_MAX_LENGTH} characters
        - avoid sensational claims, keyword stuffing, and facts not supported by the source
        - output JSON only
      PROMPT
    end

    def strip_code_fence(response)
      response.to_s.strip.sub(/\A```(?:json)?\s*/i, "").sub(/\s*```\z/, "")
    end

    def validate(value)
      title = value["title"].to_s.strip
      description = value["description"].to_s.strip
      tags = Array(value["tags"]).map { |tag| tag.to_s.delete_prefix("#").strip }.reject(&:empty?).uniq

      raise "YouTube title is empty" if title.empty?
      raise "YouTube title exceeds #{TITLE_MAX_LENGTH} characters" if title.length > TITLE_MAX_LENGTH
      raise "YouTube title contains invalid characters" if title.match?(/[<>]/)
      raise "YouTube description is empty" if description.empty?
      if description.bytesize > DESCRIPTION_MAX_BYTES
        raise "YouTube description exceeds #{DESCRIPTION_MAX_BYTES} bytes"
      end
      raise "YouTube description contains invalid characters" if description.match?(/[<>]/)
      unless TAG_COUNT_RANGE.cover?(tags.length)
        raise "YouTube tags must contain #{TAG_COUNT_RANGE.begin}-#{TAG_COUNT_RANGE.end} distinct values"
      end
      raise "YouTube tags exceed #{TAGS_MAX_LENGTH} characters" if youtube_tags_length(tags) > TAGS_MAX_LENGTH

      { "title" => title, "description" => description, "tags" => tags }
    end

    def stringify_keys(hash)
      hash.each_with_object({}) { |(key, value), result| result[key.to_s] = value }
    end

    def youtube_tags_length(tags)
      tags.sum { |tag| tag.length + (tag.include?(" ") ? 2 : 0) } + tags.length - 1
    end
  end
end
