require "test_helper"
require "ith_growth/outputs/writer"

class WriterTest < Minitest::Test
  def test_writes_nested_file
    Dir.mktmpdir do |dir|
      writer = IthGrowth::Outputs::Writer.new(base_dir: dir)
      path = writer.write("a/b/test.md", "hello")

      assert_equal "hello", File.read(path)
      assert File.exist?(File.join(dir, "a/b/test.md"))
    end
  end
end
