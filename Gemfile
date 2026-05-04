source "https://rubygems.org"

gemspec

rails_version = ENV["RAILS_VERSION"]
gem "rails", "~> #{rails_version}.0" if rails_version

group :development, :test do
  gem "rspec-rails"
  gem "webmock"
  gem "sqlite3"
  gem "simplecov", require: false
end
