namespace :herald do
  desc "Generate Herald instruction MD from annotated models and services"
  task generate_instructions: :environment do
    Herald.registry.build!
    path = Herald::InstructionGenerator.new.write!
    puts "Herald instructions written to #{path}"
  end

  desc "Register Telegram webhook with your bot"
  task setup_webhook: :environment do
    Herald.configuration.validate!
    url = ENV.fetch("HERALD_WEBHOOK_URL") { raise "Set HERALD_WEBHOOK_URL (e.g. https://yourapp.com/herald/webhook)" }
    validator = Herald::Telegram::WebhookValidator.new
    client = Herald::Telegram::Client.new
    result = client.set_webhook(url: url, secret_token: validator.webhook_secret_token)
    puts "Webhook registered: #{result}"
  end
end
