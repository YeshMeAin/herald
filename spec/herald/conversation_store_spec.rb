require "spec_helper"

RSpec.describe Herald::ConversationStore do
  subject(:store) { described_class.new }

  before do
    Herald.configure do |c|
      c.llm_api_key = "test-key"
      c.llm_provider = :anthropic
      c.conversation_compression_threshold = 20
      c.conversation_ttl = 60
    end
  end

  describe "#for_chat" do
    it "creates a new conversation for an unknown chat_id" do
      conv = store.for_chat(42)
      expect(conv).to be_a(Herald::Conversation)
      expect(conv.chat_id).to eq(42)
    end

    it "returns the same conversation for the same chat_id" do
      conv1 = store.for_chat(42)
      conv2 = store.for_chat(42)
      expect(conv1).to be(conv2)
    end

    it "returns different conversations for different chat_ids" do
      conv1 = store.for_chat(42)
      conv2 = store.for_chat(99)
      expect(conv1).not_to be(conv2)
    end

    it "cleans up expired conversations" do
      conv = store.for_chat(42)
      conv.add_user_message("hello")
      allow(Time).to receive(:now).and_return(Time.now + 120)

      store.for_chat(99)
      new_conv = store.for_chat(42)
      expect(new_conv).not_to be(conv)
    end
  end

  describe "#compress_conversation" do
    it "calls the LLM and compresses the conversation" do
      stub_request(:post, "https://api.anthropic.com/v1/messages")
        .to_return(
          status: 200,
          headers: { "content-type" => "application/json" },
          body: {
            content: [{ type: "text", text: "User discussed widgets and updated quantities." }]
          }.to_json
        )

      conv = store.for_chat(42)
      5.times { |i| conv.add_user_message("msg #{i}") }

      store.compress_conversation(conv)

      expect(conv.summary).to eq("User discussed widgets and updated quantities.")
      expect(conv.messages.length).to eq(4)
    end

    it "does not crash on LLM failure" do
      stub_request(:post, "https://api.anthropic.com/v1/messages")
        .to_return(status: 500, body: "Internal Server Error")

      conv = store.for_chat(42)
      conv.add_user_message("hello")

      expect { store.compress_conversation(conv) }.not_to raise_error
    end

    it "skips compression when messages are empty" do
      conv = store.for_chat(42)
      store.compress_conversation(conv)
      expect(conv.summary).to be_nil
    end
  end

  describe "#clear_chat" do
    it "removes the conversation" do
      conv1 = store.for_chat(42)
      store.clear_chat(42)
      conv2 = store.for_chat(42)
      expect(conv2).not_to be(conv1)
    end
  end

  describe "#reset!" do
    it "clears all conversations" do
      store.for_chat(42)
      store.for_chat(99)
      store.reset!
      expect(store.for_chat(42).messages).to be_empty
      expect(store.for_chat(99).messages).to be_empty
    end
  end
end
