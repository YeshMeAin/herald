require "simplecov"
SimpleCov.start do
  add_filter "/spec/"
  add_filter "/dummy/"
  track_files "lib/**/*.rb"
  track_files "app/**/*.rb"
end

ENV["RAILS_ENV"] = "test"
ENV["DATABASE_URL"] = "sqlite3::memory:"

require "rails"
require "active_record/railtie"
require "action_controller/railtie"
require "herald"
require "webmock/rspec"
require_relative "dummy/config/environment"
require "rspec/rails"

ActiveRecord::Schema.verbose = false
ActiveRecord::Schema.define(version: 1) do
  create_table :widgets, force: true do |t|
    t.string :name, null: false
    t.integer :quantity, default: 0
    t.timestamps
  end
end

require_relative "dummy/app/models/application_record"
require_relative "dummy/app/models/widget"

WebMock.disable_net_connect!

RSpec.configure do |config|
  config.use_transactional_fixtures = true

  config.before(:each) do
    Herald.reset!
    Herald::Agentable.registered_classes.clear
  end

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end
