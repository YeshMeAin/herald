require "faraday"
require "json"

module Herald
  module Telegram
    class Client
      BASE_URL = "https://api.telegram.org"

      def initialize(token: Herald.configuration.telegram_bot_token)
        @token = token
        @conn = Faraday.new(url: BASE_URL) do |f|
          f.request :json
          f.response :json
        end
      end

      def send_message(chat_id:, text:)
        post("sendMessage", chat_id: chat_id, text: text)
      end

      def set_webhook(url:, secret_token:)
        post("setWebhook", url: url, secret_token: secret_token)
      end

      private

      def post(method, body)
        response = @conn.post("/bot#{@token}/#{method}", body)
        parsed = response.body
        raise Error, "Telegram API error: #{parsed["description"]}" unless parsed["ok"]
        parsed["result"]
      end
    end
  end
end
