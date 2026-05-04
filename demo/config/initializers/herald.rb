Herald.configure do |config|
  config.telegram_bot_token = ENV.fetch("HERALD_TELEGRAM_TOKEN", "demo-token")
  config.telegram_user_id   = ENV.fetch("HERALD_TELEGRAM_USER_ID", "123456")
  config.llm_api_key        = ENV.fetch("HERALD_LLM_API_KEY") { raise "Set HERALD_LLM_API_KEY" }
  config.llm_provider       = ENV.fetch("HERALD_LLM_PROVIDER", "anthropic").to_sym
  config.instructions_path  = File.expand_path("../../config/herald_instructions.md", __dir__)
end
