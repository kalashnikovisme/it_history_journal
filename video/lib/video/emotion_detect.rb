require "json"

module Video
  class EmotionDetect
    EMOTIONS = %w[
      normal_smile happy excited confident mischievous thinking analyzing
      neutral tired sleeping shocked mind_blown panic nervous crying angry
      furious embarrassed eye_roll facepalm shrug thumbs_up thumbs_down
      victory dead progress disaster idea coding coffee
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

    def assign_emotions(segments, transcript)
      numbered = segments.each_with_index.map do |seg, i|
        "#{i + 1}. [#{fmt_time(seg[:start])} – #{fmt_time(seg[:end])}] #{seg[:text]}"
      end.join("\n")

      response = @client.chat(
        messages: [{ role: "user", content: build_prompt(numbered, transcript) }],
        model: "gpt-4.1-nano",
        temperature: 0.3
      )

      json_match = response.match(/\[.*?\]/m)
      return fallback(segments.size) unless json_match

      parsed = JSON.parse(json_match[0])
      raw = parsed.map { |e| EMOTIONS.include?(e.to_s) ? e.to_s : "normal_smile" }
      deduplicate(raw)
    rescue => e
      warn "[emotion_detect] Emotion assignment failed: #{e.message}"
      fallback(segments.size)
    end


    def deduplicate(emotions)
      result = emotions.dup
      result.each_with_index do |emotion, i|
        next if i.zero?
        next unless result[i] == result[i - 1]

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

        Available emotions (use exact spelling):
        normal_smile — relaxed smile, default storytelling
        happy — big smile, genuinely positive moment
        excited — amazed, eyes wide; surprising or impressive fact
        confident — smug grin; stating a well-known established truth
        mischievous — sly smile; something clever, ironic, or sneaky
        thinking — hand on chin, looking up; complex or speculative topic
        analyzing — carefully inspecting; technical deep-dive or detailed explanation
        neutral — expressionless; dry purely factual delivery
        tired — sleepy, low energy; tedious or exhausting context
        sleeping — asleep; something remarkably boring
        shocked — eyes wide, mouth open; genuinely surprising revelation
        mind_blown — "brain exploded"; paradigm shift, changed everything
        panic — scared, hands on head; something went very wrong
        nervous — awkward smile, sweat drop; uncertain or risky outcome
        crying — tears; sad, tragic, or deeply disappointing event
        angry — clearly angry; injustice or frustrating outcome
        furious — maximum rage; extreme outrage
        embarrassed — awkward smile; uncomfortable or unfortunate situation
        eye_roll — rolling eyes; obvious, overdue, or ironic development
        facepalm — hand covering face; clearly wrong decision was made
        shrug — "I don't know"; still debated or nobody knows
        thumbs_up — success; clear achievement or positive result
        thumbs_down — failure; clear setback or negative result
        victory — celebrating; major win or landmark moment
        dead — comedic "I'm dead" reaction to absurdity
        progress — happy with results; gradual step forward
        disaster — disappointed; things collapsed or went badly
        idea — lightbulb moment; breakthrough or insight
        coding — focused at the computer; intense technical work
        coffee — exhausted programmer with coffee; long hard effort

        Full transcript (actual speech):
        #{transcript}

        Segments to label (from scene plan):
        #{numbered_segments}

        Rules:
        - NEVER repeat the same emotion for two consecutive segments — always switch
        - Default to normal_smile for calm historical narration
        - Return ONLY a JSON array of emotion strings, one per segment, in order
        - Example for 4 segments: ["normal_smile", "excited", "mind_blown", "thumbs_up"]
      PROMPT
    end
  end
end
