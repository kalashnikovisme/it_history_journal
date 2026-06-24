module Video
  class FfmpegComposer
    BACKGROUND_MUSIC  = File.join("video", "audio", "background.mp3")
    BACKGROUND_VOLUME = 0.15
    SAMPLES_DIR       = File.join("video", "audio", "samples")

    # Maps output filename → sample filename (without extension).
    PLATFORMS = {
      "instagram" => "instagram",
      "shorts"    => "youtube",
      "tiktok"    => "tiktok"
    }.freeze

    def initialize(output_paths)
      @paths = output_paths
    end

    # Composes one MP4 per platform by:
    #   - freeze-framing the last video frame for the sample duration
    #   - concatenating narration.mp3 + platform sample audio
    #   - mixing with background music
    # Returns a hash { "instagram" => path, "shorts" => path, "tiktok" => path }.
    def compose_all
      ensure_ffmpeg!
      webm = @paths.browser_recording_webm
      mp3  = @paths.narration_mp3

      raise "Browser recording not found: #{webm}"            unless File.exist?(webm)
      raise "Narration audio not found: #{mp3}"               unless File.exist?(mp3)
      raise "Background music not found: #{BACKGROUND_MUSIC}" unless File.exist?(BACKGROUND_MUSIC)

      results = {}
      PLATFORMS.each do |platform, sample_name|
        sample_mp3 = File.join(SAMPLES_DIR, "#{sample_name}.mp3")
        raise "Sample not found: #{sample_mp3}" unless File.exist?(sample_mp3)

        output         = @paths.platform_mp4(platform)
        narr_duration  = probe_duration(mp3)
        sample_dur     = probe_duration(sample_mp3)
        total_duration = narr_duration + sample_dur

        args = [
          "ffmpeg", "-y",
          "-i", webm,
          "-i", mp3,
          "-i", sample_mp3,
          "-stream_loop", "-1", "-i", BACKGROUND_MUSIC,
          "-filter_complex",
            "[0:v]tpad=stop_mode=clone:stop=-1[vext];" \
            "[1:a][2:a]concat=n=2:v=0:a=1[narr_full];" \
            "[3:a]volume=#{BACKGROUND_VOLUME}[bg];" \
            "[narr_full][bg]amix=inputs=2:duration=first[aout]",
          "-map", "[vext]",
          "-map", "[aout]",
          "-t", total_duration.to_s,
          "-c:v", "libx264",
          "-pix_fmt", "yuv420p",
          "-c:a", "aac",
          "-movflags", "+faststart",
          output
        ]

        success = system(*args)
        raise "ffmpeg failed to compose #{platform}.mp4 (exit #{$?.exitstatus})" unless success

        results[platform] = output
      end

      results
    end

    private

    def probe_duration(path)
      output = `ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "#{path}" 2>&1`.strip
      duration = output.to_f
      raise "ffprobe returned invalid duration for #{path}: #{output.inspect}" if duration <= 0
      duration
    end

    def ensure_ffmpeg!
      raise "ffmpeg not found." unless system("ffmpeg -version > /dev/null 2>&1")
    end
  end
end
