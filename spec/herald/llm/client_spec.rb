require "spec_helper"
require "aws-sdk-bedrockruntime"

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

    it "uses custom llm_model when set" do
      Herald.configuration.llm_model = "claude-opus-4-20250514"

      stub = stub_request(:post, "https://api.anthropic.com/v1/messages")
        .with { |req| JSON.parse(req.body)["model"] == "claude-opus-4-20250514" }
        .to_return(
          status: 200,
          headers: { "content-type" => "application/json" },
          body: { content: [{ type: "text", text: "ok" }] }.to_json
        )

      client.call("test", system_prompt: "prompt")
      expect(stub).to have_been_requested
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

  describe "#call with bedrock" do
    let(:bedrock_client) { instance_double(Aws::BedrockRuntime::Client) }

    before do
      Herald.configure do |c|
        c.llm_provider = :bedrock
        c.aws_access_key_id = "AKIATEST"
        c.aws_secret_access_key = "secret"
        c.aws_region = "us-east-1"
        c.llm_model = "anthropic.claude-3-sonnet-20240229-v1:0"
      end

      allow(Aws::BedrockRuntime::Client).to receive(:new).and_return(bedrock_client)
    end

    subject(:client) { described_class.new }

    it "sends a message via Converse API and returns response text" do
      content_block = double("content_block", text: '{"action": "none", "message": "Hello"}')
      message = double("message", content: [content_block])
      output = double("output", message: message)
      response = double("response", output: output)

      expect(bedrock_client).to receive(:converse).with(
        model_id: "anthropic.claude-3-sonnet-20240229-v1:0",
        messages: [{ role: "user", content: [{ text: "hello" }] }],
        system: [{ text: "You are an agent" }]
      ).and_return(response)

      result = client.call("hello", system_prompt: "You are an agent")
      expect(result).to eq('{"action": "none", "message": "Hello"}')
    end

    it "sends full conversation history" do
      messages = [
        { role: "user", content: "show widget 1" },
        { role: "assistant", content: "Widget 1: Bolt" },
        { role: "user", content: "update its quantity" }
      ]

      content_block = double("content_block", text: "ok")
      message = double("message", content: [content_block])
      output = double("output", message: message)
      response = double("response", output: output)

      expect(bedrock_client).to receive(:converse).with(
        model_id: "anthropic.claude-3-sonnet-20240229-v1:0",
        messages: [
          { role: "user", content: [{ text: "show widget 1" }] },
          { role: "assistant", content: [{ text: "Widget 1: Bolt" }] },
          { role: "user", content: [{ text: "update its quantity" }] }
        ],
        system: [{ text: "prompt" }]
      ).and_return(response)

      client.call("ignored", system_prompt: "prompt", messages: messages)
    end

    it "raises on Bedrock service error" do
      expect(bedrock_client).to receive(:converse).and_raise(
        Aws::BedrockRuntime::Errors::ValidationException.new(nil, "Invalid model ID")
      )

      expect { client.call("test", system_prompt: "prompt") }
        .to raise_error(Herald::Error, /Bedrock API error: Invalid model ID/)
    end

    it "creates client with configured credentials" do
      content_block = double("content_block", text: "ok")
      message = double("message", content: [content_block])
      output = double("output", message: message)
      response = double("response", output: output)
      allow(bedrock_client).to receive(:converse).and_return(response)

      expect(Aws::BedrockRuntime::Client).to receive(:new).with(
        region: "us-east-1",
        credentials: instance_of(Aws::Credentials)
      ).and_return(bedrock_client)

      client.call("test", system_prompt: "prompt")
    end
  end
end
