module Video
  class FfmpegComposer
    def initialize(output_paths)
      @paths = output_paths
    end

    # Combines browser-recording.webm + narration.mp3 → final.mp4
    def compose
      ensure_ffmpeg!
      webm = @paths.browser_recording_webm
      mp3  = @paths.narration_mp3
      mp4  = @paths.final_mp4

      unless File.exist?(webm)
        raise "Browser recording not found: #{webm}"
      end
      unless File.exist?(mp3)
        raise "Narration audio not found: #{mp3}"
      end

      args = [
        "ffmpeg", "-y",
        "-i", webm,
        "-i", mp3,
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
