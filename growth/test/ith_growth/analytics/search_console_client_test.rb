require "test_helper"
require "ith_growth/analytics/search_console_client"

class SearchConsoleClientTest < Minitest::Test
  def client
    IthGrowth::Analytics::SearchConsoleClient.new(
      site_url: "https://example.com",
      credentials_path: "/fake/path.json"
    )
  end

  GSC_QUERY_RESPONSE = {
    "rows" => [
      { "keys" => ["history of mp3"], "clicks" => 42, "impressions" => 980, "ctr" => 0.0429, "position" => 4.2 },
      { "keys" => ["karlheinz brandenburg"], "clicks" => 18, "impressions" => 310, "ctr" => 0.0581, "position" => 6.7 }
    ]
  }.freeze

  GSC_PAGE_RESPONSE = {
    "rows" => [
      { "keys" => ["https://example.com/articles/mp3"], "clicks" => 60, "impressions" => 1200, "ctr" => 0.05, "position" => 3.1 }
    ]
  }.freeze

  def test_parse_response_maps_query_rows
    rows = client.parse_response(GSC_QUERY_RESPONSE)

    assert_equal 2, rows.size
    assert_equal "history of mp3", rows[0][:dimension]
    assert_equal 42, rows[0][:clicks]
    assert_equal 980, rows[0][:impressions]
    assert_in_delta 0.0429, rows[0][:ctr], 0.0001
    assert_in_delta 4.2, rows[0][:position], 0.01
  end

  def test_parse_response_handles_empty
    assert_empty client.parse_response({})
    assert_empty client.parse_response({ "rows" => [] })
  end

  def test_format_as_markdown_queries
    rows = client.parse_response(GSC_QUERY_RESPONSE)
    md = client.format_as_markdown(rows)

    assert_includes md, "| Query |"
    assert_includes md, "history of mp3"
    assert_includes md, "42"
    assert_includes md, "4.3%"
    assert_includes md, "4.2"
  end

  def test_format_as_markdown_pages
    rows = client.parse_response(GSC_PAGE_RESPONSE)
    md = client.format_as_markdown(rows, dimension_label: "Page")

    assert_includes md, "| Page |"
    assert_includes md, "https://example.com/articles/mp3"
    assert_includes md, "5.0%"
  end

  def test_format_as_markdown_empty
    assert_equal "_No data_", client.format_as_markdown([])
  end
end
