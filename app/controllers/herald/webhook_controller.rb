module Herald
  class WebhookController < ActionController::API
    before_action :validate_webhook!
    before_action :authorize_user!

    def receive
      user_message = params.dig(:message, :text)
      return head :ok unless user_message

      system_prompt = File.read(Herald.configuration.instructions_path)
      llm_response = llm_client.call(user_message, system_prompt: system_prompt)
      parsed = response_parser.parse(llm_response)

      if parsed[:action] == "none"
        reply(parsed[:message])
      else
        result = dispatcher.dispatch(parsed[:action], parsed[:params])
        reply(result)
      end
    rescue Herald::Error => e
      reply("Error: #{e.message}")
    rescue => e
      Rails.logger.error("[Herald] #{e.class}: #{e.message}")
      reply("Something went wrong. Please try again.")
    end

    private

    def validate_webhook!
      head :unauthorized unless validator.valid_secret_token?(request)
    end

    def authorize_user!
      head :unauthorized unless validator.authorized_user?(params.to_unsafe_h)
    end

    def reply(text)
      chat_id = params.dig(:message, :chat, :id)
      telegram_client.send_message(chat_id: chat_id, text: text)
      head :ok
    end

    def validator
      @validator ||= Telegram::WebhookValidator.new
    end

    def llm_client
      @llm_client ||= LLM::Client.new
    end

    def response_parser
      @response_parser ||= LLM::ResponseParser.new
    end

    def dispatcher
      @dispatcher ||= Dispatcher.new
    end

    def telegram_client
      @telegram_client ||= Telegram::Client.new
    end
  end
end
