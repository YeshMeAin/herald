require "rails"
require "active_record/railtie"
require "action_controller/railtie"
require_relative "../../lib/herald"

module HeraldDemo
  class Application < Rails::Application
    config.eager_load = true
    config.hosts.clear
    config.logger = Logger.new($stdout)
    config.log_level = :info
    config.secret_key_base = "demo-secret-key-not-for-production"

    config.autoload_paths << File.expand_path("../app/models", __dir__)
  end
end
