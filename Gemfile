# frozen_string_literal: true

source "https://rubygems.org"

gemspec

gem "irb"
gem "rake", "~> 13.0"
gem "rspec", "~> 3.0"

group :development, :test do
  gem "bootsnap", require: false
  gem "rails", "~> 7.2"
  gem "sqlite3"
  gem "rspec-rails", "~> 6.1"
  gem "capybara"
  gem "cuprite"
  gem "debug"

  # Required by the dummy app used in system specs
  gem "sprockets-rails"
  gem "importmap-rails"
  gem "turbo-rails"
  gem "stimulus-rails"
  gem "puma"
end
