require "tempfile"
require_relative "../video/lib/video/telegram_notifier"

RSpec.describe Video::TelegramNotifier do
  it "sends the video, title, full description, link-free description, and tags separately" do
    notifier = described_class.new(token: "token", chat_id: "122018070")
    requests = []
    allow(notifier).to receive(:post) { |method, fields| requests << [method, fields] }
    youtube = {
      "title" => "Title",
      "description" => <<~DESCRIPTION.strip,
        Description with details.

        Website: https://history.purple-magic.com
        Support: https://patreon.com/cw/kalashnikovisme
      DESCRIPTION
      "tags" => ["tag one", "tag two"]
    }

    Tempfile.create(["final", ".mp4"]) do |video|
      notifier.deliver(video.path, youtube)
    end

    expect(requests.map(&:first)).to eq(%w[sendVideo sendMessage sendMessage sendMessage sendMessage])
    expect(requests[0][1]).to include(chat_id: "122018070", video: an_instance_of(File))
    expect(requests[1][1]).to eq(chat_id: "122018070", text: "Title")
    expect(requests[2][1]).to eq(chat_id: "122018070", text: youtube.fetch("description"))
    expect(requests[3][1]).to eq(
      chat_id: "122018070",
      text: "Description with details.\nWebsite:\nSupport:"
    )
    expect(requests[4][1]).to eq(chat_id: "122018070", text: "tag one, tag two")
  end

  it "uses string field names for multipart encoding" do
    notifier = described_class.new(token: "token", chat_id: "122018070")
    response = Net::HTTPOK.new("1.1", "200", "OK")
    response.instance_variable_set(:@body, JSON.generate(ok: true, result: {}))
    response.instance_variable_set(:@read, true)
    request = nil
    http = instance_double(Net::HTTP)
    allow(http).to receive(:request) { |value| request = value; response }
    allow(Net::HTTP).to receive(:start).and_yield(http)

    notifier.send(:post, "sendMessage", chat_id: "122018070", text: "Title")

    form_fields = request.instance_variable_get(:@body_data)
    expect(form_fields.map(&:first)).to eq(%w[chat_id text])
  end
end
