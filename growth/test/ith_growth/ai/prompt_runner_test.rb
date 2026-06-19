require "test_helper"
require "ith_growth/ai/fake_client"
require "ith_growth/ai/prompt_runner"

class PromptRunnerTest < Minitest::Test
  def test_renders_template_variables
    runner = IthGrowth::AI::PromptRunner.new(client: IthGrowth::AI::FakeClient.new)
    rendered = runner.render(template: "conversion", variables: {
      project_name: "P",
      site_url: "S",
      patreon_url: "Patreon",
      boosty_url: "Boosty",
      article_title: "Title",
      article_body: "Body"
    })

    assert_includes rendered, "Title"
    refute_includes rendered, "{{article_title}}"
  end
end
