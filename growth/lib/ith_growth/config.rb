require "yaml"

module IthGrowth
  class Config
    DEFAULT_PATH = "config/config.yml"

    attr_reader :data, :path

    def self.load(path = ENV.fetch("ITH_GROWTH_CONFIG", DEFAULT_PATH))
      source = File.exist?(path) ? path : "config/config.example.yml"
      new(YAML.safe_load_file(source, aliases: true), source)
    rescue Errno::ENOENT => e
      raise Error, "Config file not found: #{e.message}"
    end

    def initialize(data, path)
      @data = data || {}
      @path = path
    end

    def [](key)
      data.fetch(key.to_s)
    end

    def dig(*keys)
      data.dig(*keys.map(&:to_s))
    end

    def output_dir
      dig(:project, :output_dir) || "./output"
    end

    def content_dir
      dig(:project, :content_dir)
    end

    def site_url
      dig(:project, :site_url)
    end

    def ai_provider
      dig(:ai, :provider) || "fake"
    end

    def ai_model
      dig(:ai, :model)
    end

    class Error < StandardError; end
  end
end
