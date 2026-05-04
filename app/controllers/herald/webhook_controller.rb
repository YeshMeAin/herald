module Herald
  class WebhookController < ActionController::API
    before_action :validate_webhook!
    before_action :authorize_user!

    def receive
      user_message = params.dig(:message, :text)
      return head :ok unless user_message

      chat_id = params.dig(:message, :chat, :id)
      conversation = Herald.conversation_store.for_chat(chat_id)
      conversation.add_user_message(user_message)

      system_prompt = File.read(Herald.configuration.instructions_path)
      llm_response = llm_client.call(
        user_message,
        system_prompt: system_prompt,
        messages: conversation.llm_messages
      )

      parsed = response_parser.parse(llm_response)

      if parsed[:action] == "none"
        response_text = parsed[:message]
      else
        response_text = dispatcher.dispatch(parsed[:action], parsed[:params])
      end

      conversation.add_assistant_message(response_text)
      reply(response_text, chat_id: chat_id)
    rescue Herald::Error => e
      reply("Error: #{e.message}", chat_id: params.dig(:message, :chat, :id))
    rescue => e
      Rails.logger.error("[Herald] #{e.class}: #{e.message}")
      reply("Something went wrong. Please try again.", chat_id: params.dig(:message, :chat, :id))
    end

    private

    def validate_webhook!
      head :unauthorized unless validator.valid_secret_token?(request)
    end

    def authorize_user!
      head :unauthorized unless validator.authorized_user?(params.to_unsafe_h)
    end

    def reply(text, chat_id:)
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
