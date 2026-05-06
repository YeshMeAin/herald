require "faraday"
require "json"

module Herald
  module LLM
    class Client
      PROVIDERS = {
        anthropic: {
          url: "https://api.anthropic.com/v1/messages",
          default_model: "claude-sonnet-4-6-20250514"
        },
        openai: {
          url: "https://api.openai.com/v1/chat/completions",
          default_model: "gpt-4o"
        },
        bedrock: {}
      }.freeze

      def initialize(config: Herald.configuration)
        @config = config
        unless PROVIDERS.key?(config.llm_provider)
          raise Error, "Unknown LLM provider: #{config.llm_provider}"
        end
      end

      def call(user_message, system_prompt:, messages: nil)
        msgs = messages || [{ role: "user", content: user_message }]
        case @config.llm_provider
        when :anthropic then call_anthropic(msgs, system_prompt)
        when :openai then call_openai(msgs, system_prompt)
        when :bedrock then call_bedrock(msgs, system_prompt)
        end
      end

      private

      def model
        @config.llm_model || PROVIDERS.dig(@config.llm_provider, :default_model)
      end

      def call_anthropic(messages, system_prompt)
        conn = Faraday.new do |f|
          f.request :json
          f.response :json
        end

        response = conn.post(PROVIDERS[:anthropic][:url]) do |req|
          req.headers["x-api-key"] = @config.llm_api_key
          req.headers["anthropic-version"] = "2023-06-01"
          req.headers["content-type"] = "application/json"
          req.body = {
            model: model,
            max_tokens: 1024,
            system: system_prompt,
            messages: messages
          }
        end

        body = response.body
        raise Error, "Anthropic API error: #{body["error"]&.dig("message")}" if body["error"]
        body.dig("content", 0, "text")
      end

      def call_openai(messages, system_prompt)
        conn = Faraday.new do |f|
          f.request :json
          f.response :json
        end

        response = conn.post(PROVIDERS[:openai][:url]) do |req|
          req.headers["Authorization"] = "Bearer #{@config.llm_api_key}"
          req.headers["content-type"] = "application/json"
          req.body = {
            model: model,
            messages: [{ role: "system", content: system_prompt }] + messages
          }
        end

        body = response.body
        raise Error, "OpenAI API error: #{body.dig("error", "message")}" if body["error"]
        body.dig("choices", 0, "message", "content")
      end

      def call_bedrock(messages, system_prompt)
        require "aws-sdk-bedrockruntime"

        client = Aws::BedrockRuntime::Client.new(
          region: @config.aws_region,
          credentials: Aws::Credentials.new(
            @config.aws_access_key_id,
            @config.aws_secret_access_key
          )
        )

        bedrock_messages = messages.map do |msg|
          { role: msg[:role] || msg["role"], content: [{ text: msg[:content] || msg["content"] }] }
        end

        response = client.converse(
          model_id: model,
          messages: bedrock_messages,
          system: [{ text: system_prompt }]
        )

        response.output.message.content[0].text
      rescue Aws::BedrockRuntime::Errors::ServiceError => e
        raise Error, "Bedrock API error: #{e.message}"
      end
    end
  end
end
