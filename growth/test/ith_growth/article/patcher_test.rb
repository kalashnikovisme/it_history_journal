require "test_helper"
require "ith_growth/article/patcher"

class PatcherTest < Minitest::Test
  def setup
    @tmpdir = Dir.mktmpdir
    @patcher = IthGrowth::Article::Patcher.new
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  def write(content)
    path = File.join(@tmpdir, "content.md")
    File.write(path, content)
    path
  end

  def test_updates_existing_field
    path = write(<<~MD)
      ---
      title: "Old Title"
      excerpt: "Old excerpt"
      ---
      Body text
    MD

    @patcher.apply(path, "title" => "New Title")
    result = File.read(path)

    assert_includes result, 'title: "New Title"'
    refute_includes result, "Old Title"
    assert_includes result, "Body text"
  end

  def test_adds_missing_field
    path = write(<<~MD)
      ---
      title: "Some Title"
      ---
      Body
    MD

    @patcher.apply(path, "excerpt" => "New excerpt")

    assert_includes File.read(path), 'excerpt: "New excerpt"'
  end

  def test_updates_updated_at
    path = write(<<~MD)
      ---
      title: "Title"
      updated_at: "2020-01-01"
      ---
      Body
    MD

    @patcher.apply(path, {})
    result = File.read(path)

    assert_includes result, "updated_at: \"#{Date.today}\""
    refute_includes result, "2020-01-01"
  end

  def test_preserves_body
    path = write(<<~MD)
      ---
      title: "Title"
      ---

      ## Section

      Body with *markdown*.
    MD

    @patcher.apply(path, "title" => "New Title")
    result = File.read(path)

    assert_includes result, "## Section"
    assert_includes result, "Body with *markdown*."
  end

  def test_escapes_double_quotes_in_value
    path = write(<<~MD)
      ---
      title: "Old"
      ---
      Body
    MD

    @patcher.apply(path, "title" => 'Say "hello"')
    assert_includes File.read(path), 'title: "Say \\"hello\\""'
  end

  def test_no_op_on_missing_frontmatter
    path = write("No frontmatter\nJust body")

    @patcher.apply(path, "title" => "New Title")

    assert_equal "No frontmatter\nJust body", File.read(path)
  end

  def test_patches_multiple_fields
    path = write(<<~MD)
      ---
      title: "Old"
      excerpt: "Old excerpt"
      ---
      Body
    MD

    @patcher.apply(path, "title" => "New Title", "excerpt" => "New excerpt")
    result = File.read(path)

    assert_includes result, 'title: "New Title"'
    assert_includes result, 'excerpt: "New excerpt"'
  end
end
