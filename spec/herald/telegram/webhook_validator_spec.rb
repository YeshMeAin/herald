require "spec_helper"

RSpec.describe Herald::Telegram::WebhookValidator do
  before do
    Herald.configure do |c|
      c.telegram_bot_token = "test-bot-token"
      c.telegram_user_id = "12345"
    end
  end

  subject(:validator) { described_class.new }

  describe "#valid_secret_token?" do
    let(:expected_token) { Digest::SHA256.hexdigest("herald:test-bot-token") }

    it "returns true for matching secret token" do
      request = double(headers: { "X-Telegram-Bot-Api-Secret-Token" => expected_token })
      expect(validator.valid_secret_token?(request)).to be true
    end

    it "returns false for wrong secret token" do
      request = double(headers: { "X-Telegram-Bot-Api-Secret-Token" => "wrong" })
      expect(validator.valid_secret_token?(request)).to be false
    end

    it "returns false when header is missing" do
      request = double(headers: {})
      expect(validator.valid_secret_token?(request)).to be false
    end
  end

  describe "#authorized_user?" do
    it "returns true for the whitelisted user" do
      data = { "message" => { "from" => { "id" => 12345 } } }
      expect(validator.authorized_user?(data)).to be true
    end

    it "handles string user IDs" do
      data = { "message" => { "from" => { "id" => "12345" } } }
      expect(validator.authorized_user?(data)).to be true
    end

    it "returns false for a different user" do
      data = { "message" => { "from" => { "id" => 99999 } } }
      expect(validator.authorized_user?(data)).to be false
    end

    it "returns false for missing from data" do
      data = { "message" => {} }
      expect(validator.authorized_user?(data)).to be false
    end

    it "returns false for missing message" do
      data = {}
      expect(validator.authorized_user?(data)).to be false
    end
  end

  describe "#webhook_secret_token" do
    it "returns a deterministic SHA256 hash" do
      expected = Digest::SHA256.hexdigest("herald:test-bot-token")
      expect(validator.webhook_secret_token).to eq(expected)
    end
  end
end
