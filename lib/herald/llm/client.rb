require "faraday"
require "json"

module Herald
  module LLM
    class Client
      PROVIDERS = {
        anthropic: {
          url: "https://api.anthropic.com/v1/messages",
          model: "claude-sonnet-4-6-20250514",
          auth_header: "x-api-key"
        },
        openai: {
          url: "https://api.openai.com/v1/chat/completions",
          model: "gpt-4o",
          auth_header: "Authorization"
        }
      }.freeze

      def initialize(config: Herald.configuration)
        @config = config
        @provider = PROVIDERS.fetch(config.llm_provider) do
          raise Error, "Unknown LLM provider: #{config.llm_provider}"
        end
      end

      def call(user_message, system_prompt:, messages: nil)
        msgs = messages || [{ role: "user", content: user_message }]
        case @config.llm_provider
        when :anthropic then call_anthropic(msgs, system_prompt)
        when :openai then call_openai(msgs, system_prompt)
        end
      end

      private

      def call_anthropic(messages, system_prompt)
        conn = Faraday.new do |f|
          f.request :json
          f.response :json
        end

        response = conn.post(@provider[:url]) do |req|
          req.headers["x-api-key"] = @config.llm_api_key
          req.headers["anthropic-version"] = "2023-06-01"
          req.headers["content-type"] = "application/json"
          req.body = {
            model: @provider[:model],
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

        response = conn.post(@provider[:url]) do |req|
          req.headers["Authorization"] = "Bearer #{@config.llm_api_key}"
          req.headers["content-type"] = "application/json"
          req.body = {
            model: @provider[:model],
            messages: [{ role: "system", content: system_prompt }] + messages
          }
        end

        body = response.body
        raise Error, "OpenAI API error: #{body.dig("error", "message")}" if body["error"]
        body.dig("choices", 0, "message", "content")
      end
    end
  end
end
