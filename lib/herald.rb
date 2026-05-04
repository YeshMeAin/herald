require "herald/version"
require "herald/configuration"
require "herald/engine"
require "herald/agentable"
require "herald/action_descriptor"
require "herald/action_registry"
require "herald/dispatcher"
require "herald/instruction_generator"
require "herald/llm/client"
require "herald/llm/response_parser"
require "herald/telegram/client"
require "herald/telegram/webhook_validator"

module Herald
  class Error < StandardError; end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def registry
      @registry ||= ActionRegistry.new
    end

    def reset!
      @configuration = Configuration.new
      @registry = ActionRegistry.new
    end
  end
end
