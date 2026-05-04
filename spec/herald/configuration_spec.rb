require "spec_helper"

RSpec.describe Herald::Configuration do
  subject(:config) { described_class.new }

  describe "defaults" do
    it "defaults llm_provider to :anthropic" do
      expect(config.llm_provider).to eq(:anthropic)
    end

    it "defaults instructions_path to Rails config dir" do
      expect(config.instructions_path.to_s).to end_with("config/herald_instructions.md")
    end
  end

  describe "#instructions_path" do
    it "uses custom path when set" do
      config.instructions_path = "/custom/path.md"
      expect(config.instructions_path).to eq("/custom/path.md")
    end

    it "falls back to Rails default when nil" do
      config.instructions_path = nil
      expect(config.instructions_path.to_s).to include("herald_instructions.md")
    end
  end

  describe "#validate!" do
    it "raises when telegram_bot_token is missing" do
      config.telegram_user_id = "123"
      config.llm_api_key = "key"

      expect { config.validate! }.to raise_error(Herald::Error, /telegram_bot_token/)
    end

    it "raises when telegram_user_id is missing" do
      config.telegram_bot_token = "token"
      config.llm_api_key = "key"

      expect { config.validate! }.to raise_error(Herald::Error, /telegram_user_id/)
    end

    it "raises when llm_api_key is missing" do
      config.telegram_bot_token = "token"
      config.telegram_user_id = "123"

      expect { config.validate! }.to raise_error(Herald::Error, /llm_api_key/)
    end

    it "does not raise when all required fields are present" do
      config.telegram_bot_token = "token"
      config.telegram_user_id = "123"
      config.llm_api_key = "key"

      expect { config.validate! }.not_to raise_error
    end
  end
end
