require "fileutils"

module Video
  class OutputPaths
    attr_reader :media_dir, :meta_dir

    def initialize(article_info)
      lang     = article_info[:lang]
      mon      = article_info[:month_abbr]
      dd       = article_info[:day].to_s.rjust(2, "0")
      slug_dir = article_info[:slug_dir]

      @media_dir = File.join("video", "output", lang, mon, dd, slug_dir)
      @meta_dir  = File.join("video", "meta",   lang, mon, dd, slug_dir)
    end

    def ensure_dir!
      FileUtils.mkdir_p(@media_dir)
      FileUtils.mkdir_p(@meta_dir)
    end

    # Shared across all videos — lives at video/prompt.txt
    def prompt_txt = File.join("video", "prompt.txt")

    # Text / metadata files → video/meta/
    def narration_txt      = File.join(@meta_dir, "narration.txt")
    def scenes_json        = File.join(@meta_dir, "scenes.json")
    def metadata_json      = File.join(@meta_dir, "metadata.json")
    def tts_request_json   = File.join(@meta_dir, "tts-request.json")
    def render_config_json = File.join(@meta_dir, "render-config.json")

    # Audio / video files → video/output/
    def narration_mp3          = File.join(@media_dir, "narration.mp3")
    def browser_recording_webm = File.join(@media_dir, "browser-recording.webm")
    def final_mp4              = File.join(@media_dir, "final.mp4")
  end
end
