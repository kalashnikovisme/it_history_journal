require "test_helper"
require "ith_growth/ai/fake_client"
require "ith_growth/ai/prompt_runner"
require "ith_growth/config"
require "ith_growth/logger"
require "ith_growth/outputs/writer"
require "ith_growth/workflows/article_analysis_workflow"

class ArticleAnalysisWorkflowTest < Minitest::Test
  def test_writes_analysis_outputs_with_fake_client
    Dir.mktmpdir do |dir|
      article_path = File.join(dir, "unix.md")
      File.write(article_path, "# UNIX\nBody")
      config_path = File.join(dir, "config.yml")
      File.write(config_path, <<~YAML)
        project:
          name: IT History Journal
          site_url: https://example.com
          output_dir: #{dir}/output
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

      files = IthGrowth::Workflows::ArticleAnalysisWorkflow
        .new(config: config, writer: writer, logger: logger, prompt_runner: runner)
        .run(article_path)

      assert_equal 2, files.size
      assert File.exist?(File.join(config.output_dir, "articles/unix/analysis.md"))
      assert File.exist?(File.join(config.output_dir, "articles/unix/analysis.json"))
    end
  end
end
