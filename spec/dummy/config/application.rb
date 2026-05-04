require "rails"
require "active_record/railtie"
require "action_controller/railtie"

module Dummy
  class Application < Rails::Application
    config.eager_load = false
    config.hosts.clear
  end
end
