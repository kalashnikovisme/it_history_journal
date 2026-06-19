require "test_helper"
require "ith_growth/config"

class ConfigTest < Minitest::Test
  def test_loads_yaml_config
    Dir.mktmpdir do |dir|
      path = File.join(dir, "config.yml")
      File.write(path, "project:\n  output_dir: ./out\nai:\n  provider: fake\n")

      config = IthGrowth::Config.load(path)

      assert_equal "./out", config.output_dir
      assert_equal "fake", config.ai_provider
    end
  end
end
