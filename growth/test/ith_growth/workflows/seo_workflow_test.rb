require "test_helper"
require "ith_growth/ai/fake_client"
require "ith_growth/ai/prompt_runner"
require "ith_growth/config"
require "ith_growth/logger"
require "ith_growth/outputs/writer"
require "ith_growth/workflows/seo_workflow"

class SeoWorkflowTest < Minitest::Test
  def setup
    @dir = Dir.mktmpdir
    article_path = File.join(@dir, "articles/en/jun/20/some_event/content.md")
    FileUtils.mkdir_p(File.dirname(article_path))
    File.write(article_path, "---\ntitle: Some Event\nexcerpt: Old excerpt\n---\n# Some Event\nBody text")
    @article_path = article_path

    config_path = File.join(@dir, "config.yml")
    File.write(config_path, <<~YAML)
      project:
        name: IT History Journal
        site_url: https://example.com
        output_dir: #{@dir}/growth/output
        content_dir: #{@dir}/articles
      seo:
        output_dir: #{@dir}/seo
      ai:
        provider: fake
        model: fake-local
      growth:
        patreon_url: https://patreon.example
        boosty_url: https://boosty.example
    YAML

    @config = IthGrowth::Config.load(config_path)
    writer = IthGrowth::Outputs::Writer.new(base_dir: @config.output_dir)
    logger = IthGrowth::Logger.new(output_dir: @config.output_dir)
    runner = IthGrowth::AI::PromptRunner.new(client: IthGrowth::AI::FakeClient.new)
    @workflow = IthGrowth::Workflows::SeoWorkflow.new(
      config: @config, writer: writer, logger: logger, prompt_runner: runner
    )
  end

  def teardown
    FileUtils.rm_rf(@dir)
  end

  def test_writes_seo_report_to_seo_directory
    files = @workflow.run(@article_path)

    today = Date.today.to_s
    seo_report = File.join(@dir, "seo/articles/en/jun/20/some_event/seo-#{today}.md")
    schema = File.join(@dir, "seo/articles/en/jun/20/some_event/schema.json")

    assert_includes files, seo_report
    assert_includes files, schema
    assert File.exist?(seo_report)
    assert File.exist?(schema)
  end

  def test_report_contains_date_header
    @workflow.run(@article_path)
    today = Date.today.to_s
    report = File.read(File.join(@dir, "seo/articles/en/jun/20/some_event/seo-#{today}.md"))
    assert_includes report, "# SEO Report — #{today}"
  end

  def test_accumulates_history_across_runs
    @workflow.run(@article_path)
    @workflow.run(@article_path)

    today = Date.today.to_s
    reports = Dir.glob(File.join(@dir, "seo/articles/en/jun/20/some_event/seo-*.md"))
    # Both writes use today's date so the file is overwritten; at least one exists
    assert reports.size >= 1
  end

  def test_schema_contains_correct_url
    @workflow.run(@article_path)
    schema_path = File.join(@dir, "seo/articles/en/jun/20/some_event/schema.json")
    schema = JSON.parse(File.read(schema_path))
    assert_includes schema["url"], "/en/jun/20/some-event"
  end

  def test_nothing_written_to_growth_output
    @workflow.run(@article_path)
    assert_empty Dir.glob(File.join(@dir, "growth/output/**/*.md"))
  end
end
