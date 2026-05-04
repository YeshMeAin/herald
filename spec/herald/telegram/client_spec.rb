require "spec_helper"

RSpec.describe Herald::Telegram::Client do
  before do
    Herald.configure { |c| c.telegram_bot_token = "bot-token-123" }
  end

  subject(:client) { described_class.new }

  describe "#send_message" do
    it "posts to the Telegram sendMessage endpoint" do
      stub = stub_request(:post, "https://api.telegram.org/botbot-token-123/sendMessage")
        .with(body: { chat_id: 42, text: "Hello" }.to_json)
        .to_return(
          status: 200,
          headers: { "content-type" => "application/json" },
          body: { ok: true, result: { message_id: 1 } }.to_json
        )

      client.send_message(chat_id: 42, text: "Hello")
      expect(stub).to have_been_requested
    end

    it "raises on Telegram API error" do
      stub_request(:post, "https://api.telegram.org/botbot-token-123/sendMessage")
        .to_return(
          status: 400,
          headers: { "content-type" => "application/json" },
          body: { ok: false, description: "Bad Request: chat not found" }.to_json
        )

      expect { client.send_message(chat_id: 0, text: "Hi") }
        .to raise_error(Herald::Error, /chat not found/)
    end
  end

  describe "#set_webhook" do
    it "posts to the Telegram setWebhook endpoint" do
      stub = stub_request(:post, "https://api.telegram.org/botbot-token-123/setWebhook")
        .with(body: { url: "https://example.com/webhook", secret_token: "abc" }.to_json)
        .to_return(
          status: 200,
          headers: { "content-type" => "application/json" },
          body: { ok: true, result: true }.to_json
        )

      client.set_webhook(url: "https://example.com/webhook", secret_token: "abc")
      expect(stub).to have_been_requested
    end
  end
end
