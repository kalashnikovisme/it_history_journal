require "test_helper"
require "ith_growth/article/slugger"

class SluggerTest < Minitest::Test
  def test_generates_ascii_slug
    assert_equal "history-of-unix", IthGrowth::Article::Slugger.slug("History of UNIX!")
  end

  def test_falls_back_for_empty_slug
    assert_equal "article", IthGrowth::Article::Slugger.slug("!!!")
  end
end
