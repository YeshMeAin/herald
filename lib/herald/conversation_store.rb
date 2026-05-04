module Herald
  class ConversationStore
    COMPRESSION_PROMPT = <<~PROMPT.freeze
      Summarize the following conversation between a user and an application agent.
      Focus on: what entities were discussed (names, IDs), what actions were taken,
      what the outcomes were, and any pending requests or context the user might
      reference in future messages.
      Be concise but preserve all important details. Write in past tense.
    PROMPT

    def initialize
      @conversations = {}
      @mutex = Mutex.new
    end

    def for_chat(chat_id)
      cleanup_expired!
      config = Herald.configuration
      @mutex.synchronize do
        @conversations[chat_id] ||= Conversation.new(
          chat_id: chat_id,
          compression_threshold: config.conversation_compression_threshold,
          ttl: config.conversation_ttl
        )
      end
    end

    def compress_conversation(conversation)
      messages_to_summarize = conversation.messages.dup
      return if messages_to_summarize.empty?

      formatted = messages_to_summarize.map do |msg|
        "#{msg[:role]}: #{msg[:content]}"
      end.join("\n")

      llm = LLM::Client.new
      summary = llm.call(formatted, system_prompt: COMPRESSION_PROMPT)

      @mutex.synchronize do
        conversation.compress!(summary)
      end
    rescue => e
      Rails.logger.error("[Herald] Conversation compression failed: #{e.message}")
    end

    def clear_chat(chat_id)
      @mutex.synchronize do
        @conversations.delete(chat_id)
      end
    end

    def reset!
      @mutex.synchronize do
        @conversations.clear
      end
    end

    private

    def cleanup_expired!
      @mutex.synchronize do
        @conversations.reject! { |_, conv| conv.expired? }
      end
    end
  end
end
