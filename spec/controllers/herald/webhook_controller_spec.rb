require "spec_helper"

RSpec.describe Herald::WebhookController, type: :controller do
  routes { Herald::Engine.routes }

  let(:secret_token) { Digest::SHA256.hexdigest("herald:bot-token") }
  let(:chat_id) { 42 }
  let(:user_id) { 12345 }

  before do
    Herald.configure do |c|
      c.telegram_bot_token = "bot-token"
      c.telegram_user_id = user_id.to_s
      c.llm_api_key = "llm-key"
    end

    stub_request(:post, %r{api\.telegram\.org}).to_return(
      status: 200,
      headers: { "content-type" => "application/json" },
      body: { ok: true, result: { message_id: 1 } }.to_json
    )
  end

  def webhook_params(text: "show widget 1")
    {
      message: {
        text: text,
        from: { id: user_id },
        chat: { id: chat_id }
      }
    }
  end

  def do_post(params: webhook_params, secret: secret_token)
    request.headers["X-Telegram-Bot-Api-Secret-Token"] = secret if secret
    post :receive, params: params, as: :json
  end

  describe "authentication" do
    it "returns 401 without secret token header" do
      do_post(secret: nil)
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 with wrong secret token" do
      do_post(secret: "bad-token")
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 for unauthorized user" do
      params = webhook_params.deep_merge(message: { from: { id: 99999 } })
      do_post(params: params)
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "message processing" do
    let(:instructions_path) { Rails.root.join("tmp", "test_instructions.md") }

    before do
      Herald.configuration.instructions_path = instructions_path.to_s
      File.write(instructions_path, "You are an agent.")

      Herald::Agentable.registered_classes << Widget
      Widget.agent_actions(only: [:show])
      Herald.registry.build!
    end

    after { File.delete(instructions_path) if File.exist?(instructions_path) }

    it "returns 200 for messages without text" do
      params = { message: { from: { id: user_id }, chat: { id: chat_id } } }
      do_post(params: params)
      expect(response).to have_http_status(:ok)
    end

    it "dispatches an action and replies" do
      widget = Widget.create!(name: "Bolt", quantity: 10)

      llm_stub = stub_request(:post, "https://api.anthropic.com/v1/messages")
        .to_return(
          status: 200,
          headers: { "content-type" => "application/json" },
          body: {
            content: [{ type: "text", text: "{\"action\": \"widget.show\", \"params\": {\"id\": #{widget.id}}}" }]
          }.to_json
        )

      telegram_stub = stub_request(:post, "https://api.telegram.org/botbot-token/sendMessage")
        .to_return(
          status: 200,
          headers: { "content-type" => "application/json" },
          body: { ok: true, result: { message_id: 1 } }.to_json
        )

      do_post
      expect(response).to have_http_status(:ok)
      expect(llm_stub).to have_been_requested
      expect(telegram_stub).to have_been_requested
    end

    it "replies with message when action is none" do
      stub_request(:post, "https://api.anthropic.com/v1/messages")
        .to_return(
          status: 200,
          headers: { "content-type" => "application/json" },
          body: {
            content: [{ type: "text", text: '{"action": "none", "message": "I can\'t do that"}' }]
          }.to_json
        )

      telegram_stub = stub_request(:post, "https://api.telegram.org/botbot-token/sendMessage")
        .with(body: hash_including("text" => "I can't do that"))
        .to_return(
          status: 200,
          headers: { "content-type" => "application/json" },
          body: { ok: true, result: { message_id: 1 } }.to_json
        )

      do_post
      expect(telegram_stub).to have_been_requested
    end

    it "replies with error message on Herald::Error" do
      stub_request(:post, "https://api.anthropic.com/v1/messages")
        .to_return(
          status: 200,
          headers: { "content-type" => "application/json" },
          body: {
            content: [{ type: "text", text: '{"action": "widget.show", "params": {}}' }]
          }.to_json
        )

      telegram_stub = stub_request(:post, "https://api.telegram.org/botbot-token/sendMessage")
        .with(body: hash_including("text" => /Missing required params/))
        .to_return(
          status: 200,
          headers: { "content-type" => "application/json" },
          body: { ok: true, result: { message_id: 1 } }.to_json
        )

      do_post
      expect(telegram_stub).to have_been_requested
    end

    it "replies with generic error on unexpected exceptions" do
      stub_request(:post, "https://api.anthropic.com/v1/messages")
        .to_return(status: 500, body: "Internal Server Error")

      telegram_stub = stub_request(:post, "https://api.telegram.org/botbot-token/sendMessage")
        .with(body: hash_including("text" => "Something went wrong. Please try again."))
        .to_return(
          status: 200,
          headers: { "content-type" => "application/json" },
          body: { ok: true, result: { message_id: 1 } }.to_json
        )

      do_post
      expect(telegram_stub).to have_been_requested
    end
  end
end
