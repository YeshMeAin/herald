module Herald
  class Configuration
    attr_accessor :telegram_bot_token,
                  :telegram_user_id,
                  :llm_api_key,
                  :llm_provider,
                  :llm_model,
                  :instructions_path,
                  :conversation_compression_threshold,
                  :conversation_ttl,
                  :aws_access_key_id,
                  :aws_secret_access_key,
                  :aws_region

    def initialize
      @llm_provider = :bedrock
      @aws_region = "us-east-1"
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

      case llm_provider
      when :bedrock
        raise Error, "Herald: aws_access_key_id is required for Bedrock" unless aws_access_key_id
        raise Error, "Herald: aws_secret_access_key is required for Bedrock" unless aws_secret_access_key
        raise Error, "Herald: llm_model is required for Bedrock" unless llm_model
      when :anthropic, :openai
        raise Error, "Herald: llm_api_key is required" unless llm_api_key
      end
    end
  end
end
