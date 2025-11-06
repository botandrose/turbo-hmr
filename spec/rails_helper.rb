# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"
require File.expand_path("dummy/config/environment", __dir__)

require "rspec/rails"
require "capybara/rspec"
require "capybara/cuprite"
require "debug"

Dir["#{__dir__}/support/**/*.rb"].sort.each { |file| require file }

Capybara.server = :webrick
Capybara.default_max_wait_time = 5

Capybara.register_driver(:my_cuprite) do |app|
  Capybara::Cuprite::Driver.new(app, {
    window_size: [1400, 900],
    js_errors: true,
    headless: true,
  })
end

Capybara.default_driver = :my_cuprite
Capybara.javascript_driver = :my_cuprite

RSpec.configure do |config|
  config.use_transactional_fixtures = false

  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  config.before :each, type: :system do
    driven_by :my_cuprite
  end
end
