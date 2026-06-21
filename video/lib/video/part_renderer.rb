module Video
  class PartRenderer
    PARTS = {
      "calendar" => {
        duration: ScenePlanner::CALENDAR_DURATION,
        scenes: [
          {
            "id" => "calendar",
            "start" => 0.0,
            "duration" => ScenePlanner::CALENDAR_DURATION
          }
        ]
      }
    }.freeze

    def initialize(article_info, output_paths)
      @renderer = Renderer.new(article_info, output_paths)
      @paths = output_paths
    end

    def render(name)
      part = PARTS.fetch(name) do
        raise ArgumentError, "Unknown video part: #{name}. Available parts: #{PARTS.keys.join(', ')}"
      end

      output_path = @paths.part_webm(name)
      @renderer.render(
        part[:scenes],
        part[:duration],
        output_path: output_path,
        config_path: @paths.part_render_config_json(name)
      )
      output_path
    end
  end
end
