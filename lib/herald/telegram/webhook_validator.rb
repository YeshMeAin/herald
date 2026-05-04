module Herald
  module Telegram
    class WebhookValidator
      def initialize(config: Herald.configuration)
        @config = config
      end

      def valid_secret_token?(request)
        header = request.headers["X-Telegram-Bot-Api-Secret-Token"]
        return false unless header
        ActiveSupport::SecurityUtils.secure_compare(header, webhook_secret_token)
      end

      def authorized_user?(message_data)
        from_id = message_data.dig("message", "from", "id")&.to_s
        from_id == @config.telegram_user_id.to_s
      end

      def webhook_secret_token
        Digest::SHA256.hexdigest("herald:#{@config.telegram_bot_token}")
      end
    end
  end
end
