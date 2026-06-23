module Video
  class FfmpegComposer
    BACKGROUND_MUSIC = File.join("video", "background.mp3")
    BACKGROUND_VOLUME = 0.15

    def initialize(output_paths)
      @paths = output_paths
    end

    # Combines browser-recording.webm + narration.mp3 + background.mp3 → final.mp4
    def compose
      ensure_ffmpeg!
      webm = @paths.browser_recording_webm
      mp3  = @paths.narration_mp3
      mp4  = @paths.final_mp4

      raise "Browser recording not found: #{webm}"   unless File.exist?(webm)
      raise "Narration audio not found: #{mp3}"      unless File.exist?(mp3)
      raise "Background music not found: #{BACKGROUND_MUSIC}" unless File.exist?(BACKGROUND_MUSIC)

      args = [
        "ffmpeg", "-y",
        "-i", webm,
        "-i", mp3,
        "-stream_loop", "-1", "-i", BACKGROUND_MUSIC,
        "-filter_complex",
          "[1:a]volume=1.0[narr];[2:a]volume=#{BACKGROUND_VOLUME}[bg];[narr][bg]amix=inputs=2:duration=first[aout]",
        "-map", "0:v",
        "-map", "[aout]",
        "-c:v", "libx264",
        "-pix_fmt", "yuv420p",
        "-c:a", "aac",
        "-shortest",
        "-movflags", "+faststart",
        mp4
      ]

      success = system(*args)
      raise "ffmpeg failed to compose final.mp4 (exit #{$?.exitstatus})" unless success

      mp4
    end

    private

    def ensure_ffmpeg!
      result = system("ffmpeg -version > /dev/null 2>&1")
      raise "ffmpeg not found. Install it in the Docker image (apt-get install ffmpeg)." unless result
    end
  end
end
