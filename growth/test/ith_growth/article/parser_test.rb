require "test_helper"
require "ith_growth/article/parser"
require "ith_growth/article/slugger"

class ParserTest < Minitest::Test
  def test_parses_frontmatter_title_and_body
    Dir.mktmpdir do |dir|
      path = File.join(dir, "article.md")
      File.write(path, "---\ntitle: ARPANET Notes\nslug: arpanet-notes\n---\n# Ignored\nBody")

      article = IthGrowth::Article::Parser.new.parse(path)

      assert_equal "ARPANET Notes", article.title
      assert_equal "arpanet-notes", article.slug
      assert_includes article.body, "Body"
    end
  end

  def test_uses_markdown_heading_when_frontmatter_missing
    Dir.mktmpdir do |dir|
      path = File.join(dir, "article.md")
      File.write(path, "# Mainframes\nBody")

      article = IthGrowth::Article::Parser.new.parse(path)

      assert_equal "Mainframes", article.title
      assert_equal "mainframes", article.slug
    end
  end
end
