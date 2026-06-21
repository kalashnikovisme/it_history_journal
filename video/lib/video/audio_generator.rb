require "json"
require "fileutils"

module Video
  class AudioGenerator
    TTS_MODEL = "tts-1"
    TTS_VOICE = "onyx"

    def initialize(output_paths, openai_client)
      @paths  = output_paths
      @client = openai_client
    end

    # Generates narration.mp3 from narration text.
    # Returns audio duration in seconds (float).
    # Skips if narration.mp3 already exists unless force: true.
    def generate(narration_text, force: false)
      @paths.ensure_dir!

      unless File.exist?(@paths.narration_mp3) && !force
        request_params = {
          model:           TTS_MODEL,
          input:           narration_text,
          voice:           TTS_VOICE,
          response_format: "mp3"
        }
        File.write(@paths.tts_request_json, JSON.pretty_generate(request_params))

        @client.tts(
          text:        narration_text,
          voice:       TTS_VOICE,
          model:       TTS_MODEL,
          output_path: @paths.narration_mp3
        )
      end

      probe_duration(@paths.narration_mp3)
    end

    def probe_duration(mp3_path)
      ensure_ffprobe!
      output = `ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "#{mp3_path}" 2>&1`.strip
      duration = output.to_f
      raise "ffprobe returned invalid duration for #{mp3_path}: #{output.inspect}" if duration <= 0
      duration
    end

    private

    def ensure_ffprobe!
      result = system("ffprobe -version > /dev/null 2>&1")
      raise "ffprobe not found. Install ffmpeg (which includes ffprobe)." unless result
    end
  end
end
