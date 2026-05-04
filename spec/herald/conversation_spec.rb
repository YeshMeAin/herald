require "spec_helper"

RSpec.describe Herald::Conversation do
  subject(:conversation) { described_class.new(chat_id: 42, compression_threshold: 4, ttl: 60) }

  before do
    Herald.configure do |c|
      c.llm_api_key = "test-key"
      c.llm_provider = :anthropic
    end
  end

  describe "#add_user_message" do
    it "appends a user message" do
      conversation.add_user_message("hello")
      expect(conversation.messages.last).to eq(role: "user", content: "hello")
    end
  end

  describe "#add_assistant_message" do
    it "appends an assistant message" do
      conversation.add_assistant_message("hi there")
      expect(conversation.messages.last).to eq(role: "assistant", content: "hi there")
    end
  end

  describe "#llm_messages" do
    it "returns messages without summary prefix when no summary exists" do
      conversation.add_user_message("hello")
      conversation.add_assistant_message("hi")
      expect(conversation.llm_messages).to eq([
        { role: "user", content: "hello" },
        { role: "assistant", content: "hi" }
      ])
    end

    it "prepends summary context when summary exists" do
      conversation.add_user_message("hello")
      conversation.add_assistant_message("hi")
      conversation.compress!("User greeted the agent.")

      msgs = conversation.llm_messages
      expect(msgs.first[:content]).to include("User greeted the agent.")
      expect(msgs[1][:content]).to eq("Understood, I have the context.")
    end
  end

  describe "#expired?" do
    it "returns false when recently active" do
      expect(conversation.expired?).to be false
    end

    it "returns true after TTL" do
      conversation.add_user_message("hello")
      allow(Time).to receive(:now).and_return(Time.now + 120)
      expect(conversation.expired?).to be true
    end
  end

  describe "#needs_compression?" do
    it "returns false below threshold" do
      3.times { |i| conversation.add_user_message("msg #{i}") }
      expect(conversation.needs_compression?).to be false
    end

    it "returns true at threshold" do
      # Stub Thread.new to avoid async compression during setup
      allow(Thread).to receive(:new)
      4.times { |i| conversation.add_user_message("msg #{i}") }
      expect(conversation.needs_compression?).to be true
    end
  end

  describe "#compress!" do
    it "sets the summary and keeps recent messages" do
      allow(Thread).to receive(:new)
      6.times { |i| conversation.add_user_message("msg #{i}") }
      conversation.compress!("Summary of messages 0-5")

      expect(conversation.summary).to eq("Summary of messages 0-5")
      expect(conversation.messages.length).to eq(4)
      expect(conversation.messages.first[:content]).to eq("msg 2")
    end

    it "appends to existing summary" do
      conversation.compress!("First summary")
      conversation.compress!("Second summary")
      expect(conversation.summary).to include("First summary")
      expect(conversation.summary).to include("Second summary")
    end
  end

  describe "#clear!" do
    it "resets messages and summary" do
      conversation.add_user_message("hello")
      conversation.compress!("Some summary")
      conversation.clear!

      expect(conversation.messages).to be_empty
      expect(conversation.summary).to be_nil
    end
  end

  describe "automatic compression trigger" do
    it "spawns a compression thread at threshold" do
      thread_started = false
      allow(Thread).to receive(:new) { thread_started = true }

      4.times { |i| conversation.add_user_message("msg #{i}") }
      expect(thread_started).to be true
    end

    it "does not spawn a thread below threshold" do
      expect(Thread).not_to receive(:new)
      3.times { |i| conversation.add_user_message("msg #{i}") }
    end
  end
end
