require "json"

module Video
  class ScenePlanner
    CALENDAR_START    = 0.0
    CALENDAR_DURATION = 4.0
    TITLE_DURATION    = 3.5
    COVER_START       = 7.5   # calendar + title
    COVER_DURATION    = 4.0
    CTA_DURATION      = 5.0   # fallback for scenario-only mode

    ESTIMATED_DURATION = 55.0

    def initialize(article_info, output_paths)
      @info  = article_info
      @paths = output_paths
    end

    # Returns [scenes, reused].
    # scenes are the base rendering scenes (CTA duration = max sample duration).
    #
    # sample_durations: { "instagram" => float, "shorts" => float, "tiktok" => float }
    #   When nil (scenario-only mode), CTA_DURATION is used as fallback.
    #
    # Writes scenes-instagram.json, scenes-shorts.json, scenes-tiktok.json into meta_dir.
    # Each platform file carries `audio` on the first scene (narration.mp3) and on the
    # CTA scene (the platform sample); CTA duration equals the sample's length.
    def plan(narration_text, audio_duration, sample_durations: nil, force: false)
      @paths.ensure_dir!

      platform_files_exist = FfmpegComposer::PLATFORMS.keys.all? do |p|
        File.exist?(@paths.platform_scenes_json(p))
      end

      if platform_files_exist && !force
        base = JSON.parse(File.read(@paths.platform_scenes_json("instagram")))
        return [base, true]
      end

      ru = @info[:lang] == "ru"

      narration_duration  = audio_duration || ESTIMATED_DURATION
      sample_durations  ||= FfmpegComposer::PLATFORMS.keys.each_with_object({}) { |p, h| h[p] = CTA_DURATION }
      max_sample_duration = ru ? CTA_DURATION : sample_durations.values.max
      sentences           = split_sentences(narration_text)

      FfmpegComposer::PLATFORMS.each do |platform, sample_name|
        if ru
          cta_dur     = CTA_DURATION
          cta_start   = narration_duration - cta_dur
          sample_path = nil
        else
          cta_dur     = sample_durations.fetch(platform)
          cta_start   = narration_duration
          sample_path = File.join(FfmpegComposer::SAMPLES_DIR, "#{sample_name}.mp3")
        end
        scenes = build_scenes(sentences, narration_duration, cta_dur, cta_start)
        annotate_audio!(scenes, @paths.narration_mp3, sample_path)
        File.write(@paths.platform_scenes_json(platform), JSON.pretty_generate(scenes))
      end

      base_cta_start  = ru ? narration_duration - max_sample_duration : narration_duration
      base_scenes = build_scenes(sentences, narration_duration, max_sample_duration, base_cta_start)
      File.write(@paths.metadata_json, JSON.pretty_generate(build_metadata(base_scenes, audio_duration, max_sample_duration)))

      [base_scenes, false]
    end

    private

    def split_sentences(text)
      text
        .gsub(/([.!?…])\s+/, "\\1\n")
        .split("\n")
        .map(&:strip)
        .reject(&:empty?)
    end

    def build_scenes(sentences, narration_duration, cta_duration, cta_start = narration_duration)
      scenes = []

      scenes << {
        "id"       => "calendar",
        "start"    => CALENDAR_START,
        "duration" => CALENDAR_DURATION
      }

      scenes << {
        "id"       => "title_card",
        "start"    => CALENDAR_START + CALENDAR_DURATION,
        "duration" => TITLE_DURATION
      }

      scenes << {
        "id"       => "cover",
        "start"    => COVER_START,
        "duration" => [narration_duration - COVER_START, COVER_DURATION].max
      }

      # Facts fill the full narration window
      facts_start  = COVER_START
      facts_window = narration_duration - facts_start

      fact_sentences = sentences.select { |s| s.length > 5 }.first(10)
      fact_sentences = ["..."] if fact_sentences.empty?

      per_fact = facts_window / fact_sentences.size.to_f
      fact_sentences.each_with_index do |sentence, i|
        scenes << {
          "id"       => "fact",
          "start"    => (facts_start + i * per_fact).round(3),
          "duration" => per_fact.round(3),
          "text"     => sentence
        }
      end

      scenes << {
        "id"       => "cta",
        "start"    => cta_start.round(3),
        "duration" => cta_duration.round(3)
      }

      scenes
    end

    # Adds `audio` to the first scene (narration) and the CTA scene (sample, if given).
    def annotate_audio!(scenes, narration_path, sample_path)
      scenes.first["audio"] = narration_path
      scenes.find { |s| s["id"] == "cta" }&.tap { |s| s["audio"] = sample_path } if sample_path
    end

    def build_metadata(scenes, narration_duration, cta_duration)
      total = narration_duration ? (narration_duration + cta_duration).round(3) : nil
      @info.merge(
        "scenes"         => scenes,
        "total_duration" => total,
        "scene_count"    => scenes.size
      )
    end
  end
end
