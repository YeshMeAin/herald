require "spec_helper"

RSpec.describe Herald::LLM::ResponseParser do
  subject(:parser) { described_class.new }

  describe "#parse" do
    it "parses a clean JSON response" do
      raw = '{"action": "widget.show", "params": {"id": 5}}'
      result = parser.parse(raw)
      expect(result[:action]).to eq("widget.show")
      expect(result[:params]).to eq("id" => 5)
    end

    it "extracts JSON from markdown code blocks" do
      raw = "Here's the action:\n```json\n{\"action\": \"widget.index\", \"params\": {}}\n```"
      result = parser.parse(raw)
      expect(result[:action]).to eq("widget.index")
      expect(result[:params]).to eq({})
    end

    it "extracts JSON from code blocks without language tag" do
      raw = "```\n{\"action\": \"widget.show\", \"params\": {\"id\": 1}}\n```"
      result = parser.parse(raw)
      expect(result[:action]).to eq("widget.show")
    end

    it "extracts JSON embedded in prose" do
      raw = "I'll look that up for you. {\"action\": \"widget.show\", \"params\": {\"id\": 3}} Let me know if you need more."
      result = parser.parse(raw)
      expect(result[:action]).to eq("widget.show")
      expect(result[:params]).to eq("id" => 3)
    end

    it "returns none action when action is none" do
      raw = '{"action": "none", "message": "I cannot do that"}'
      result = parser.parse(raw)
      expect(result[:action]).to eq("none")
      expect(result[:message]).to eq("I cannot do that")
    end

    it "returns none action when action key is missing" do
      raw = '{"message": "something"}'
      result = parser.parse(raw)
      expect(result[:action]).to eq("none")
    end

    it "returns none with original text on parse failure" do
      raw = "I don't understand what you mean."
      result = parser.parse(raw)
      expect(result[:action]).to eq("none")
      expect(result[:message]).to eq(raw)
    end

    it "defaults params to empty hash when missing" do
      raw = '{"action": "widget.index"}'
      result = parser.parse(raw)
      expect(result[:params]).to eq({})
    end

    it "stringify keys in params" do
      raw = '{"action": "widget.show", "params": {"id": 1}}'
      result = parser.parse(raw)
      expect(result[:params].keys).to all(be_a(String))
    end

    it "uses raw_text as message for none action without message field" do
      raw = '{"action": "none"}'
      result = parser.parse(raw)
      expect(result[:message]).to eq(raw)
    end
  end
end
