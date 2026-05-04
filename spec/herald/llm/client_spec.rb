require "spec_helper"

RSpec.describe Herald::LLM::Client do
  before do
    Herald.configure do |c|
      c.llm_api_key = "test-key"
      c.llm_provider = :anthropic
    end
  end

  describe "#initialize" do
    it "raises for unknown providers" do
      Herald.configuration.llm_provider = :unknown
      expect { described_class.new }.to raise_error(Herald::Error, /Unknown LLM provider/)
    end
  end

  describe "#call with anthropic" do
    subject(:client) { described_class.new }

    it "sends a message and returns the response text" do
      stub_request(:post, "https://api.anthropic.com/v1/messages")
        .with(
          headers: { "x-api-key" => "test-key", "anthropic-version" => "2023-06-01" }
        )
        .to_return(
          status: 200,
          headers: { "content-type" => "application/json" },
          body: {
            content: [{ type: "text", text: '{"action": "widget.show", "params": {"id": 1}}' }]
          }.to_json
        )

      result = client.call("show widget 1", system_prompt: "You are an agent")
      expect(result).to eq('{"action": "widget.show", "params": {"id": 1}}')
    end

    it "raises on API error" do
      stub_request(:post, "https://api.anthropic.com/v1/messages")
        .to_return(
          status: 400,
          headers: { "content-type" => "application/json" },
          body: { error: { type: "invalid_request", message: "Bad request" } }.to_json
        )

      expect { client.call("test", system_prompt: "prompt") }
        .to raise_error(Herald::Error, /Anthropic API error: Bad request/)
    end

    it "sends full conversation history when messages are provided" do
      messages = [
        { role: "user", content: "show widget 1" },
        { role: "assistant", content: "Widget 1: Bolt" },
        { role: "user", content: "update its quantity to 20" }
      ]

      stub = stub_request(:post, "https://api.anthropic.com/v1/messages")
        .with { |req| JSON.parse(req.body)["messages"] == messages.map(&:stringify_keys) }
        .to_return(
          status: 200,
          headers: { "content-type" => "application/json" },
          body: {
            content: [{ type: "text", text: '{"action": "widget.update", "params": {"id": 1, "quantity": 20}}' }]
          }.to_json
        )

      client.call("ignored", system_prompt: "You are an agent", messages: messages)
      expect(stub).to have_been_requested
    end
  end

  describe "#call with openai" do
    before { Herald.configuration.llm_provider = :openai }
    subject(:client) { described_class.new }

    it "sends a message and returns the response text" do
      stub_request(:post, "https://api.openai.com/v1/chat/completions")
        .with(
          headers: { "Authorization" => "Bearer test-key" }
        )
        .to_return(
          status: 200,
          headers: { "content-type" => "application/json" },
          body: {
            choices: [{ message: { content: '{"action": "none"}' } }]
          }.to_json
        )

      result = client.call("hello", system_prompt: "You are an agent")
      expect(result).to eq('{"action": "none"}')
    end

    it "raises on API error" do
      stub_request(:post, "https://api.openai.com/v1/chat/completions")
        .to_return(
          status: 400,
          headers: { "content-type" => "application/json" },
          body: { error: { message: "Invalid key" } }.to_json
        )

      expect { client.call("test", system_prompt: "prompt") }
        .to raise_error(Herald::Error, /OpenAI API error: Invalid key/)
    end
  end
end
