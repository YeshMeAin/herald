require "json"

module Herald
  module LLM
    class ResponseParser
      def parse(raw_text)
        json = extract_json(raw_text)
        parsed = JSON.parse(json)

        action = parsed["action"]
        return { action: "none", message: parsed["message"] || raw_text } if action == "none" || action.nil?

        {
          action: action,
          params: (parsed["params"] || {}).stringify_keys
        }
      rescue JSON::ParserError
        { action: "none", message: raw_text }
      end

      private

      def extract_json(text)
        if text =~ /```(?:json)?\s*(\{.*?\})\s*```/m
          $1
        elsif text =~ /(\{.*\})/m
          $1
        else
          text
        end
      end
    end
  end
end
