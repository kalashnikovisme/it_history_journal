require "tempfile"
require_relative "../video/lib/video/telegram_notifier"

RSpec.describe Video::TelegramNotifier do
  it "sends the video, title, description, and tags as four separate messages" do
    notifier = described_class.new(token: "token", chat_id: "@kalashnikovisme")
    requests = []
    allow(notifier).to receive(:post) { |method, fields| requests << [method, fields] }
    youtube = {
      "title" => "Title",
      "description" => "Description",
      "tags" => ["tag one", "tag two"]
    }

    Tempfile.create(["final", ".mp4"]) do |video|
      notifier.deliver(video.path, youtube)
    end

    expect(requests.map(&:first)).to eq(%w[sendVideo sendMessage sendMessage sendMessage])
    expect(requests[0][1]).to include(chat_id: "@kalashnikovisme", video: an_instance_of(File))
    expect(requests[1][1]).to eq(chat_id: "@kalashnikovisme", text: "Title")
    expect(requests[2][1]).to eq(chat_id: "@kalashnikovisme", text: "Description")
    expect(requests[3][1]).to eq(chat_id: "@kalashnikovisme", text: "tag one, tag two")
  end
end
