module Herald
  class Conversation
    DEFAULT_COMPRESSION_THRESHOLD = 20
    DEFAULT_TTL = 1800 # 30 minutes

    attr_reader :chat_id, :messages, :summary

    def initialize(chat_id:, compression_threshold: DEFAULT_COMPRESSION_THRESHOLD, ttl: DEFAULT_TTL)
      @chat_id = chat_id
      @compression_threshold = compression_threshold
      @ttl = ttl
      @messages = []
      @summary = nil
      @last_activity = Time.now
    end

    def add_user_message(text)
      touch!
      @messages << { role: "user", content: text }
      check_compression!
    end

    def add_assistant_message(text)
      touch!
      @messages << { role: "assistant", content: text }
    end

    def llm_messages
      msgs = []
      msgs << { role: "user", content: "Previous conversation context:\n#{@summary}" } if @summary
      msgs << { role: "assistant", content: "Understood, I have the context." } if @summary
      msgs.concat(@messages)
      msgs
    end

    def expired?
      Time.now - @last_activity > @ttl
    end

    def needs_compression?
      @messages.length >= @compression_threshold
    end

    def compress!(compressed_summary)
      existing = @summary ? "#{@summary}\n\n" : ""
      @summary = existing + compressed_summary
      recent = @messages.last(4)
      @messages = recent
    end

    def clear!
      @messages = []
      @summary = nil
      @last_activity = Time.now
    end

    private

    def touch!
      @last_activity = Time.now
    end

    def check_compression!
      return unless needs_compression?
      Thread.new { Herald.conversation_store.compress_conversation(self) }
    end
  end
end
