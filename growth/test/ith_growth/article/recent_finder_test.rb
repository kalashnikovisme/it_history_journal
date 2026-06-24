require "test_helper"
require "ith_growth/article/recent_finder"

class RecentFinderTest < Minitest::Test
  def setup
    @dir = Dir.mktmpdir
  end

  def teardown
    FileUtils.rm_rf(@dir)
  end

  def write_article(rel_path)
    path = File.join(@dir, rel_path)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, "---\ntitle: Test Article\n---\nBody text.")
    path
  end

  def finder
    IthGrowth::Article::RecentFinder.new(content_dir: @dir)
  end

  def target_path(days_ago)
    d = Date.today - days_ago
    "en/#{d.strftime("%b").downcase}/#{d.day}/some_event/content.md"
  end

  def test_finds_articles_in_directory_for_7_days_ago
    path = write_article(target_path(7))
    results = finder.find(days: 7)
    assert_equal 1, results.size
    assert_equal path, results.first[:path]
  end

  def test_excludes_articles_from_other_days
    write_article(target_path(6))
    write_article(target_path(8))
    assert_empty finder.find(days: 7)
  end

  def test_finds_articles_across_languages
    en_path = write_article(target_path(7).sub("en/", "en/"))
    ru_path = write_article(target_path(7).sub("en/", "ru/"))
    results = finder.find(days: 7)
    assert_equal 2, results.size
    assert_includes results.map { |r| r[:path] }, en_path
    assert_includes results.map { |r| r[:path] }, ru_path
  end

  def test_finds_multiple_articles_on_same_date
    d = Date.today - 7
    path_a = write_article("en/#{d.strftime("%b").downcase}/#{d.day}/event_a/content.md")
    path_b = write_article("en/#{d.strftime("%b").downcase}/#{d.day}/event_b/content.md")
    results = finder.find(days: 7)
    assert_equal 2, results.size
    assert_equal [path_a, path_b], results.map { |r| r[:path] }
  end

  def test_result_includes_target_date
    write_article(target_path(7))
    result = finder.find(days: 7).first
    assert_equal Date.today - 7, result[:date]
  end

  def test_result_includes_parsed_article
    write_article(target_path(7))
    result = finder.find(days: 7).first
    assert_equal "Test Article", result[:article].title
  end

  def test_custom_days_window
    write_article(target_path(3))
    assert_empty finder.find(days: 7)
    assert_equal 1, finder.find(days: 3).size
  end

  def test_returns_empty_when_no_articles_exist
    assert_empty finder.find(days: 7)
  end
end
