require 'rubygems'
require 'spork'

Spork.prefork do
  require 'cucumber/rails'

  Capybara.default_wait_time = 5
  Capybara.default_selector = :css

  ActionController::Base.allow_rescue = false

  begin
    DatabaseCleaner.orm = 'mongoid'
    DatabaseCleaner.strategy = :truncation
  rescue NameError
    raise "You need to add database_cleaner to your Gemfile (in the :test group) if you wish to use it."
  end

  Cucumber::Rails::Database.javascript_strategy = :truncation

  require 'email_spec/cucumber'

  WebMock.allow_net_connect!
end

Spork.each_run do
end
