source "https://rubygems.org"

gemspec

rails_version = ENV["RAILS_VERSION"]
gem "rails", "~> #{rails_version}.0" if rails_version

group :development, :test do
  gem "rspec-rails"
  gem "webmock"
  gem "sqlite3", rails_version && rails_version.to_f < 7.1 ? "~> 1.4" : ">= 2.0"
  gem "simplecov", require: false
end
