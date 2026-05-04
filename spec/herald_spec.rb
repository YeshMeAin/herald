require "spec_helper"

RSpec.describe Herald do
  describe ".configuration" do
    it "returns a Configuration instance" do
      expect(Herald.configuration).to be_a(Herald::Configuration)
    end

    it "memoizes the configuration" do
      expect(Herald.configuration).to be(Herald.configuration)
    end
  end

  describe ".configure" do
    it "yields the configuration" do
      Herald.configure do |config|
        config.telegram_bot_token = "test-token"
      end

      expect(Herald.configuration.telegram_bot_token).to eq("test-token")
    end
  end

  describe ".registry" do
    it "returns an ActionRegistry instance" do
      expect(Herald.registry).to be_a(Herald::ActionRegistry)
    end

    it "memoizes the registry" do
      expect(Herald.registry).to be(Herald.registry)
    end
  end

  describe ".reset!" do
    it "resets configuration and registry" do
      Herald.configure { |c| c.telegram_bot_token = "old" }
      old_registry = Herald.registry

      Herald.reset!

      expect(Herald.configuration.telegram_bot_token).to be_nil
      expect(Herald.registry).not_to be(old_registry)
    end
  end
end
