require "json"

module Video
  class FfmpegComposer
    BACKGROUND_MUSIC  = File.join("video", "audio", "background.mp3")
    BACKGROUND_VOLUME    = 0.08
    NARRATION_VOLUME_RU  = 1.4
    FINAL_VOLUME_RU      = 5.0
    SAMPLES_DIR       = File.join("video", "audio", "samples")

    # Maps output filename → sample filename (without extension).
    PLATFORMS = {
      "instagram" => "instagram",
      "shorts"    => "youtube",
      "tiktok"    => "tiktok"
    }.freeze

    # Probes the duration of each platform sample.
    # Returns { "instagram" => float, "shorts" => float, "tiktok" => float }.
    # Called before scene planning so CTA durations can be embedded in scene files.
    def self.probe_sample_durations
      PLATFORMS.transform_values do |sample_name|
        mp3 = File.join(SAMPLES_DIR, "#{sample_name}.mp3")
        raise "Sample not found: #{mp3}" unless File.exist?(mp3)
        out = `ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "#{mp3}" 2>&1`.strip
        dur = out.to_f
        raise "ffprobe returned invalid duration for #{mp3}: #{out.inspect}" if dur <= 0
        dur
      end
    end

    def initialize(output_paths, lang: nil, verbose: false)
      @paths   = output_paths
      @lang    = lang
      @verbose = verbose
    end

    # Composes one MP4 per platform by reading the platform scene files.
    # Audio is concatenated in the order of scenes that carry an `audio` field.
    # Total duration is derived from the last scene's start + duration.
    # Returns { "instagram" => path, "shorts" => path, "tiktok" => path }.
    def compose_all
      ensure_ffmpeg!
      raise "Background music not found: #{BACKGROUND_MUSIC}" unless File.exist?(BACKGROUND_MUSIC)

      webm = @paths.browser_recording_webm
      raise "Browser recording not found: #{webm}" unless File.exist?(webm)

      results = {}

      PLATFORMS.each_key do |platform|
        scenes_path = @paths.platform_scenes_json(platform)
        raise "Platform scenes not found: #{scenes_path}" unless File.exist?(scenes_path)

        scenes = JSON.parse(File.read(scenes_path))

        audio_segments = scenes
          .select  { |s| s["audio"] }
          .sort_by { |s| s["start"].to_f }
          .map     { |s| s["audio"] }

        raise "No audio segments defined in #{scenes_path}" if audio_segments.empty?
        audio_segments.each { |f| raise "Audio file not found: #{f}" unless File.exist?(f) }

        total_duration = if @lang == "ru"
          probe_duration(@paths.narration_mp3)
        else
          scenes.map { |s| s["start"].to_f + s["duration"].to_f }.max
        end
        output = @paths.platform_mp4(platform)
        n      = audio_segments.size

        args = ["ffmpeg", "-y"]
        args += ["-loglevel", "quiet"] unless @verbose
        args += ["-i", webm]
        audio_segments.each { |seg| args += ["-i", seg] }
        args += ["-stream_loop", "-1", "-i", BACKGROUND_MUSIC]

        bg_idx       = n + 1
        narr_volume  = @lang == "ru" ? NARRATION_VOLUME_RU : 1.0
        final_volume = @lang == "ru" ? FINAL_VOLUME_RU : 1.0

        # concat requires n≥2; with a single segment skip it and label directly
        if n == 1
          narr_filter = "[1:a]volume=#{narr_volume}[narr_full]"
        else
          audio_concat = (1..n).map { |i| "[#{i}:a]" }.join
          narr_filter  = "#{audio_concat}concat=n=#{n}:v=0:a=1[narr_raw];" \
                         "[narr_raw]volume=#{narr_volume}[narr_full]"
        end

        filter = "#{narr_filter};" \
                 "[#{bg_idx}:a]volume=#{BACKGROUND_VOLUME}[bg];" \
                 "[narr_full][bg]amix=inputs=2:duration=first[mix];" \
                 "[mix]volume=#{final_volume}[aout]"

        args += [
          "-filter_complex", filter,
          "-map", "0:v",
          "-map", "[aout]",
          "-t", total_duration.to_s,
          "-c:v", "libx264",
          "-pix_fmt", "yuv420p",
          "-c:a", "aac",
          "-movflags", "+faststart",
          output
        ]

        puts "[video] Composing #{File.basename(output)}..."
        success = system(*args)
        raise "ffmpeg failed to compose #{platform}.mp4 (exit #{$?.exitstatus})" unless success

        results[platform] = output
      end

      results
    end

    private

    def probe_duration(path)
      out = `ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "#{path}" 2>&1`.strip
      dur = out.to_f
      raise "ffprobe returned invalid duration for #{path}: #{out.inspect}" if dur <= 0
      dur
    end

    def ensure_ffmpeg!
      raise "ffmpeg not found." unless system("ffmpeg -version > /dev/null 2>&1")
    end
  end
end
