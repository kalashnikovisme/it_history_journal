require "test_helper"
require "ith_growth/ai/fake_client"
require "ith_growth/ai/prompt_runner"
require "ith_growth/config"
require "ith_growth/logger"
require "ith_growth/outputs/writer"
require "ith_growth/workflows/distribution_workflow"

class DistributionWorkflowTest < Minitest::Test
  def test_writes_distribution_files_to_distribution_directory
    Dir.mktmpdir do |dir|
      article_path = File.join(dir, "articles/en/jun/20/some_event/content.md")
      FileUtils.mkdir_p(File.dirname(article_path))
      File.write(article_path, "# Some Event\nBody text")

      config_path = File.join(dir, "config.yml")
      File.write(config_path, <<~YAML)
        project:
          name: IT History Journal
          site_url: https://example.com
          output_dir: #{dir}/growth/output
          content_dir: #{dir}/articles
        distribution:
          output_dir: #{dir}/distribution
        ai:
          provider: fake
          model: fake-local
        growth:
          patreon_url: https://patreon.example
          boosty_url: https://boosty.example
      YAML

      config = IthGrowth::Config.load(config_path)
      writer = IthGrowth::Outputs::Writer.new(base_dir: config.output_dir)
      logger = IthGrowth::Logger.new(output_dir: config.output_dir)
      runner = IthGrowth::AI::PromptRunner.new(client: IthGrowth::AI::FakeClient.new)

      files = IthGrowth::Workflows::DistributionWorkflow
        .new(config: config, writer: writer, logger: logger, prompt_runner: runner)
        .run(article_path)

      assert_equal IthGrowth::Workflows::DistributionWorkflow::PLATFORMS.size, files.size
      assert File.exist?(File.join(dir, "distribution/articles/en/jun/20/some_event/twitter.md"))
      assert File.exist?(File.join(dir, "distribution/articles/en/jun/20/some_event/linkedin.md"))
      assert_empty Dir.glob(File.join(dir, "growth/output/**/*.md"))
    end
  end
end
