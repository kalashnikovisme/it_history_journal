require "json"

module Video
  class EmotionDetect
    EMOTIONS = %w[
      normal_smile happy excited confident mischievous thinking analyzing
      neutral tired sleeping shocked mind_blown panic nervous crying angry
      furious embarrassed eye_roll facepalm shrug thumbs_up thumbs_down
      victory dead progress disaster idea coding coffee the_first_in_history
    ].freeze

    TRANSCRIPT_FILE = "transcript.json"

    def initialize(output_paths, openai_client)
      @paths  = output_paths
      @client = openai_client
    end

    EMOTIONS_DIR = File.expand_path("../../assets/emotions", __dir__).freeze

    # Raises if any emotion referenced in the platform scene files has no image file.
    def validate_emotion_images!
      emotions = load_platform_scenes
        .values
        .flat_map { |d| d[:scenes].select { |s| s["id"] == "fact" && s["emotion"] } }
        .map { |s| s["emotion"] }
        .uniq
        .sort

      missing = emotions.reject { |e| File.exist?(File.join(EMOTIONS_DIR, "#{e}.png")) }
      return if missing.empty?

      raise "Missing emotion image#{"s" if missing.size > 1}: " \
            "#{missing.map { |e| "assets/emotions/#{e}.png" }.join(", ")}"
    end

    # Enriches all platform scene files with per-fact emotion annotations.
    # The transcript is cached in meta_dir/transcript.json on first run.
    # Returns true if emotions were written, false if skipped (already done or no audio).
    def detect(force: false)
      return false unless File.exist?(@paths.narration_mp3)
      return false if !force && all_facts_annotated?

      transcript = load_or_transcribe
      return false if transcript.nil?

      platform_data = load_platform_scenes
      return false if platform_data.empty?

      # Build segments using the first platform's scenes as canonical timing
      canonical_scenes = platform_data.values.first[:scenes]
      facts = canonical_scenes.select { |s| s["id"] == "fact" }
      return false if facts.empty?

      segments = extract_segments(facts)
      emotions = assign_emotions(segments, transcript)

      platform_data.each_value do |data|
        fact_idx = 0
        data[:scenes].each do |scene|
          next unless scene["id"] == "fact"
          scene["emotion"] = emotions[fact_idx] || "normal_smile"
          fact_idx += 1
        end
        File.write(data[:path], JSON.pretty_generate(data[:scenes]))
      end

      true
    rescue => e
      warn "[emotion_detect] ERROR: #{e.message}"
      false
    end

    private

    def all_facts_annotated?
      Video::FfmpegComposer::PLATFORMS.keys.all? do |platform|
        path = @paths.platform_scenes_json(platform)
        return false unless File.exist?(path)
        scenes = JSON.parse(File.read(path))
        facts = scenes.select { |s| s["id"] == "fact" }
        facts.any? && facts.all? { |s| s["emotion"] }
      end
    end

    def load_platform_scenes
      Video::FfmpegComposer::PLATFORMS.keys.each_with_object({}) do |platform, h|
        path = @paths.platform_scenes_json(platform)
        next unless File.exist?(path)
        h[platform] = { path: path, scenes: JSON.parse(File.read(path)) }
      end
    end

    def load_or_transcribe
      transcript_path = File.join(@paths.meta_dir, TRANSCRIPT_FILE)
      if File.exist?(transcript_path)
        File.read(transcript_path).strip
      else
        text = @client.transcribe(@paths.narration_mp3)
        File.write(transcript_path, text) if text && !text.empty?
        text
      end
    end

    # Build segments from scene text fields (no word timestamps available).
    def extract_segments(facts)
      facts.map do |scene|
        { start: scene["start"].to_f, end: scene["start"].to_f + scene["duration"].to_f,
          text: scene["text"].to_s.strip }
      end
    end

    EMOTION_WINDOW = 15.0  # seconds per emotion

    def assign_emotions(segments, transcript)
      # Group 5s scenes into ~15s windows; ask GPT for one emotion per window,
      # then spread it across all scenes in the window.
      total = segments.sum { |s| s[:end] - s[:start] }
      n_groups = [(total / EMOTION_WINDOW).round, 1].max
      group_size = [(segments.size.to_f / n_groups).ceil, 1].max
      groups = segments.each_slice(group_size).to_a

      numbered = groups.each_with_index.map do |group, i|
        text = group.map { |s| s[:text] }.reject(&:empty?).join(" ")
        "#{i + 1}. [#{fmt_time(group.first[:start])} – #{fmt_time(group.last[:end])}] #{text}"
      end.join("\n")

      response = @client.chat(
        messages: [{ role: "user", content: build_prompt(numbered, transcript) }],
        model: "gpt-4.1-nano",
        temperature: 0.3
      )

      json_match = response.match(/\[.*?\]/m)
      return fallback(segments.size) unless json_match

      parsed = JSON.parse(json_match[0])

      # Each group entry maps to one emotion; spread it across all scenes in the group
      emotions = groups.each_with_index.flat_map do |group, i|
        emotion = EMOTIONS.include?(parsed[i].to_s) ? parsed[i].to_s : "normal_smile"
        Array.new(group.size, emotion)
      end

      deduplicate(emotions)
    rescue => e
      warn "[emotion_detect] Emotion assignment failed: #{e.message}"
      fallback(segments.size)
    end


    # Same emotion is allowed for at most 4 consecutive segments (15-20 s).
    # A fifth consecutive match is replaced with something different.
    def deduplicate(emotions)
      result = emotions.dup
      result.each_with_index do |_emotion, i|
        next if i < 4
        next unless result[i] == result[i - 1] && result[i] == result[i - 2] &&
                    result[i] == result[i - 3] && result[i] == result[i - 4]

        next_emotion = result[i + 1]
        pool = EMOTIONS.reject { |e| e == result[i - 1] || e == next_emotion }
        pool = EMOTIONS.reject { |e| e == result[i - 1] } if pool.empty?
        result[i] = pool.sample
      end
      result
    end

    def fallback(n)
      Array.new(n, "normal_smile")
    end

    def fmt_time(seconds)
      m = (seconds / 60).floor
      s = seconds % 60
      format("%d:%04.1f", m, s)
    end

    def build_prompt(numbered_segments, transcript)
      <<~PROMPT.strip
        You assign character emotions to narration segments for a short IT history documentary video.
        The character is a friendly programmer mascot who visually reacts to each moment being described.

        STRICT RULE — FORBIDDEN emotions. You may NOT use these unless the segment describes an
        explicit, unambiguous catastrophe, mass failure, tragedy, or extreme outrage with no positive angle:
        panic, nervous, crying, angry, furious, embarrassed, facepalm, thumbs_down, dead, disaster
        When in any doubt, pick a positive or neutral emotion instead. Most IT history is positive.

        Available emotions (use exact spelling):
        normal_smile — relaxed smile, default storytelling
        happy — big smile, genuinely positive moment
        excited — amazed, eyes wide; surprising or impressive fact
        confident — smug grin; stating a well-known established truth
        mischievous — sly smile; something clever, ironic, or sneaky
        thinking — hand on chin, looking up; complex or speculative topic
        analyzing — carefully inspecting; technical deep-dive or detailed explanation
        neutral — expressionless; dry purely factual delivery
        shocked — eyes wide, mouth open; genuinely surprising revelation
        mind_blown — "brain exploded"; paradigm shift, changed everything
        eye_roll — rolling eyes; obvious, overdue, or ironic development
        shrug — "I don't know"; still debated or nobody knows
        thumbs_up — success; clear achievement or positive result
        victory — celebrating; major win or landmark moment
        progress — happy with results; gradual step forward
        idea — lightbulb moment; breakthrough or insight
        coding — focused at the computer; intense technical work
        coffee — exhausted programmer with coffee; long hard effort
        tired — sleepy, low energy; tedious or exhausting context
        sleeping — asleep; something remarkably boring
        the_first_in_history — awe and pride; this is a historic first, a pioneering moment

        Full transcript (actual speech):
        #{transcript}

        Segments to label (from scene plan):
        #{numbered_segments}

        Rules:
        - Each entry is a ~15-second window; assign exactly one emotion per entry
        - Never use the same emotion for two consecutive entries — always vary
        - Default to normal_smile for calm historical narration
        - Return ONLY a JSON array of emotion strings, one per segment, in order
        - Example for 4 segments: ["normal_smile", "excited", "mind_blown", "thumbs_up"]
      PROMPT
    end
  end
end
