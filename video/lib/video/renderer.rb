require "json"

module Video
  class Renderer
    RENDERER_DIR = File.expand_path("../../renderer", __dir__)

    def initialize(article_info, output_paths, verbose: false)
      @info    = article_info
      @paths   = output_paths
      @verbose = verbose
    end

    def render(scenes, audio_duration, port: nil, output_path: @paths.browser_recording_webm,
               config_path: @paths.render_config_json)
      @paths.ensure_dir!
      ensure_node!
      install_renderer_deps

      config = build_render_config(scenes, audio_duration, port)
      File.write(config_path, JSON.pretty_generate(config))

      record_js = File.join(RENDERER_DIR, "record.js")
      raise "record.js not found at #{record_js}" unless File.exist?(record_js)

      cmd_parts = [
        "node", record_js,
        "--config", File.expand_path(config_path),
        "--output", File.expand_path(output_path),
        "--cover",  File.expand_path(@info[:video_cover_path])
      ]
      cmd_parts << "--quiet" unless @verbose

      success = system(*cmd_parts)
      raise "record.js failed (exit #{$?.exitstatus})" unless success
    end

    private

    def build_render_config(scenes, audio_duration, port)
      {
        "language"       => @info[:lang],
        "title"          => @info[:title],
        "date_display"   => @info[:date_display],
        "day"            => @info[:day].to_s,
        "month_name"     => @info[:month_name],
        "year"           => @info[:year].to_s,
        "slug"           => @info[:slug],
        "cover_filename" => File.basename(@info[:video_cover_path]),
        "site_url"       => "history.purple-magic.com",
        "cta_language"   => @info[:lang],
        "total_duration" => audio_duration.round(3),
        "scenes"         => scenes
      }
    end

    def install_renderer_deps
      playwright_dir = File.join(RENDERER_DIR, "node_modules", "playwright")
      return if File.exist?(playwright_dir)

      success = system("npm install --prefix #{RENDERER_DIR}")
      raise "npm install failed in #{RENDERER_DIR}" unless success
    end

    def ensure_node!
      result = system("node --version > /dev/null 2>&1")
      raise "node is not available. Install Node.js in the Docker image." unless result
    end
  end
end
