require "tmpdir"
require_relative "../video/lib/video/youtube_metadata_generator"

RSpec.describe Video::YoutubeMetadataGenerator do
  let(:info) do
    {
      lang: "en",
      title: "The Birth of XML",
      date_display: "February 10, 1998",
      content_md: "XML became a W3C recommendation."
    }
  end
  let(:response) do
    JSON.generate(
      title: "How XML Became a Web Standard",
      description: "The story behind XML and the web. Follow IT History Journal. #XML #WebHistory #Shorts",
      tags: ["XML", "web history", "W3C", "internet history", "data formats"]
    )
  end

  it "merges validated YouTube fields into existing metadata" do
    Dir.mktmpdir do |dir|
      metadata_path = File.join(dir, "metadata.json")
      File.write(metadata_path, JSON.generate("scene_count" => 4))
      paths = paths_for(metadata_path)
      client = instance_double("OpenAIClient", chat: response)

      youtube, reused = described_class.new(info, paths, client).generate("Narration")
      metadata = JSON.parse(File.read(metadata_path))

      expect(reused).to be false
      expect(youtube.fetch("title")).to eq("How XML Became a Web Standard")
      expect(metadata.fetch("scene_count")).to eq(4)
      expect(metadata.fetch("youtube")).to eq(youtube)
    end
  end

  it "reuses existing YouTube metadata without calling OpenAI" do
    Dir.mktmpdir do |dir|
      metadata_path = File.join(dir, "metadata.json")
      existing = JSON.parse(response)
      File.write(metadata_path, JSON.generate("youtube" => existing))
      paths = paths_for(metadata_path)
      client = instance_double("OpenAIClient")

      youtube, reused = described_class.new(info, paths, client).generate("Narration")

      expect(reused).to be true
      expect(youtube).to eq(existing)
    end
  end

  it "rejects metadata outside YouTube constraints" do
    Dir.mktmpdir do |dir|
      paths = paths_for(File.join(dir, "metadata.json"))
      invalid = JSON.generate(title: "x" * 101, description: "Description", tags: %w[one two three four five])
      client = instance_double("OpenAIClient", chat: invalid)

      expect {
        described_class.new(info, paths, client).generate("Narration")
      }.to raise_error("YouTube title exceeds 100 characters")
    end
  end

  it "enforces YouTube's combined tag length calculation" do
    Dir.mktmpdir do |dir|
      paths = paths_for(File.join(dir, "metadata.json"))
      tags = ["two words" * 12, "b" * 100, "c" * 100, "d" * 100, "e" * 100]
      invalid = JSON.generate(title: "Title", description: "Description", tags: tags)
      client = instance_double("OpenAIClient", chat: invalid)

      expect {
        described_class.new(info, paths, client).generate("Narration")
      }.to raise_error("YouTube tags exceed 500 characters")
    end
  end

  def paths_for(metadata_path)
    instance_double("OutputPaths", metadata_json: metadata_path, ensure_dir!: nil)
  end
end
