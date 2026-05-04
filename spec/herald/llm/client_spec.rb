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
