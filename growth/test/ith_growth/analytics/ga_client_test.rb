require "test_helper"
require "ith_growth/analytics/ga_client"

class GaClientTest < Minitest::Test
  def client
    IthGrowth::Analytics::GaClient.new(property_id: "123", credentials_path: "/fake/path.json")
  end

  GA4_RESPONSE = {
    "dimensionHeaders" => [{ "name" => "pagePath" }, { "name" => "pageTitle" }],
    "metricHeaders" => [
      { "name" => "screenPageViews" },
      { "name" => "bounceRate" },
      { "name" => "averageSessionDuration" }
    ],
    "rows" => [
      {
        "dimensionValues" => [{ "value" => "/articles/unix" }, { "value" => "UNIX History" }],
        "metricValues" => [{ "value" => "1200" }, { "value" => "0.42" }, { "value" => "145.3" }]
      },
      {
        "dimensionValues" => [{ "value" => "/articles/linux" }, { "value" => "Linux Origins" }],
        "metricValues" => [{ "value" => "800" }, { "value" => "0.55" }, { "value" => "90.0" }]
      }
    ]
  }.freeze

  def test_parse_response_maps_rows_to_hashes
    pages = client.parse_response(GA4_RESPONSE)

    assert_equal 2, pages.size
    assert_equal "/articles/unix", pages[0][:path]
    assert_equal "UNIX History", pages[0][:title]
    assert_equal 1200, pages[0][:views]
    assert_in_delta 0.42, pages[0][:bounce_rate], 0.001
    assert_in_delta 145.3, pages[0][:avg_duration], 0.001
  end

  def test_parse_response_handles_empty_rows
    pages = client.parse_response({ "rows" => [] })
    assert_empty pages
  end

  def test_parse_response_handles_missing_rows_key
    pages = client.parse_response({})
    assert_empty pages
  end

  def test_format_as_markdown_returns_table
    pages = client.parse_response(GA4_RESPONSE)
    md = client.format_as_markdown(pages)

    assert_includes md, "| Path | Title | Views"
    assert_includes md, "/articles/unix"
    assert_includes md, "1200"
    assert_includes md, "42.0%"
    assert_includes md, "145s"
  end

  def test_format_as_markdown_returns_placeholder_for_empty
    assert_equal "_No data_", client.format_as_markdown([])
  end
end
