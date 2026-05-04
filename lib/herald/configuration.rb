module Herald
  class Configuration
    attr_accessor :telegram_bot_token,
                  :telegram_user_id,
                  :llm_api_key,
                  :llm_provider,
                  :instructions_path,
                  :conversation_compression_threshold,
                  :conversation_ttl

    def initialize
      @llm_provider = :anthropic
      @instructions_path = nil
      @conversation_compression_threshold = 20
      @conversation_ttl = 1800
    end

    def instructions_path
      @instructions_path || Rails.root.join("config", "herald_instructions.md")
    end

    def validate!
      raise Error, "Herald: telegram_bot_token is required" unless telegram_bot_token
      raise Error, "Herald: telegram_user_id is required" unless telegram_user_id
      raise Error, "Herald: llm_api_key is required" unless llm_api_key
    end
  end
end
