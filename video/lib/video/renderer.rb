require "json"

module Video
  class Renderer
    RENDERER_DIR = File.expand_path("../../renderer", __dir__)

    def initialize(article_info, output_paths)
      @info  = article_info
      @paths = output_paths
    end

    def render(scenes, audio_duration, port: nil)
      @paths.ensure_dir!
      ensure_node!

      # Install renderer dependencies if needed
      install_renderer_deps

      config = build_render_config(scenes, audio_duration, port)
      File.write(@paths.render_config_json, JSON.pretty_generate(config))

      cover_path = @info[:cover_path]

      record_js = File.join(RENDERER_DIR, "record.js")
      unless File.exist?(record_js)
        raise "record.js not found at #{record_js}"
      end

      cmd_parts = [
        "node", record_js,
        "--config",  File.expand_path(@paths.render_config_json),
        "--output",  File.expand_path(@paths.browser_recording_webm),
        "--cover",   cover_path ? File.expand_path(cover_path) : ""
      ]

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
        "cover_filename" => @info[:cover_path] ? File.basename(@info[:cover_path]) : nil,
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
