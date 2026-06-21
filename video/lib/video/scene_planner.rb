require "json"

module Video
  class ScenePlanner
    CALENDAR_START    = 0.0
    CALENDAR_DURATION = 4.0
    TITLE_DURATION    = 3.5
    COVER_START       = 7.5   # calendar + title
    COVER_DURATION    = 4.0   # initial cover
    CTA_DURATION      = 5.0

    def initialize(article_info, output_paths)
      @info  = article_info
      @paths = output_paths
    end

    # Returns scenes array.
    ESTIMATED_DURATION = 55.0

    # Returns [scenes, reused].
    # Reuses existing scenes.json unless force: true.
    def plan(narration_text, audio_duration, force: false)
      @paths.ensure_dir!

      if File.exist?(@paths.scenes_json) && !force
        scenes = JSON.parse(File.read(@paths.scenes_json))
        return [scenes, true]
      end

      duration  = audio_duration || ESTIMATED_DURATION
      sentences = split_sentences(narration_text)
      scenes    = build_scenes(sentences, duration)

      File.write(@paths.scenes_json, JSON.pretty_generate(scenes))

      metadata = build_metadata(scenes, audio_duration)
      File.write(@paths.metadata_json, JSON.pretty_generate(metadata))

      [scenes, false]
    end

    private

    def split_sentences(text)
      # Split on sentence-ending punctuation followed by whitespace or end-of-string
      text
        .gsub(/([.!?…])\s+/, "\\1\n")
        .split("\n")
        .map(&:strip)
        .reject(&:empty?)
    end

    def build_scenes(sentences, audio_duration)
      scenes = []

      # Scene 0: calendar
      scenes << {
        "id"       => "calendar",
        "start"    => CALENDAR_START,
        "duration" => CALENDAR_DURATION
      }

      # Scene 1: title card
      scenes << {
        "id"       => "title_card",
        "start"    => CALENDAR_START + CALENDAR_DURATION,
        "duration" => TITLE_DURATION
      }

      # Scene 2: cover (stays as background while facts play)
      scenes << {
        "id"       => "cover",
        "start"    => COVER_START,
        "duration" => [audio_duration - COVER_START - CTA_DURATION, COVER_DURATION].max
      }

      # Fact scenes
      cta_start     = [audio_duration - CTA_DURATION, COVER_START + 2.0].max
      facts_start   = COVER_START
      facts_end     = cta_start
      facts_window  = facts_end - facts_start

      fact_sentences = sentences.select { |s| s.length > 5 }
      fact_sentences = fact_sentences[0, 10]  # cap at 10
      fact_sentences = ["..."] if fact_sentences.empty?

      n = fact_sentences.size
      per_fact = facts_window / n.to_f

      fact_sentences.each_with_index do |sentence, i|
        scenes << {
          "id"       => "fact",
          "start"    => (facts_start + i * per_fact).round(3),
          "duration" => per_fact.round(3),
          "text"     => sentence
        }
      end

      # CTA scene
      scenes << {
        "id"       => "cta",
        "start"    => cta_start.round(3),
        "duration" => CTA_DURATION
      }

      scenes
    end

    def build_metadata(scenes, audio_duration)
      @info.merge(
        "scenes"         => scenes,
        "total_duration" => audio_duration&.round(3),
        "scene_count"    => scenes.size
      )
    end
  end
end
