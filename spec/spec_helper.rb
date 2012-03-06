require 'rubygems'

if ENV["COVERAGE"]
  require 'simplecov'
  SimpleCov.start 'rails' do
    add_group 'Controllers', 'app/controllers'
    add_group 'Models', 'app/models'
    add_group 'Helpers', 'app/helpers'
    add_group 'Workers', 'app/workers'
    add_group 'Libraries', 'lib'
  end
end

require 'spork'

Spork.prefork do
  ENV["RAILS_ENV"] ||= 'test'
  require File.expand_path("../../config/environment", __FILE__)
  require 'rspec/rails'

  Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

  VCR.config do |c|
    c.cassette_library_dir = File.join(File.dirname(__FILE__), 'fixtures/vcr_cassettes')
    c.stub_with :webmock
  end

  RSpec.configure do |config|
    config.mock_with :rspec

    # Use color in STDOUT
    config.color_enabled = true
    # Use color not only in STDOUT but also in pagers and files
    config.tty = true

    # Use the specified formatter
    # config.formatter = :documentation, :progress, :html, :textmate
    config.formatter = :documentation

    # Clean up the database
    require 'database_cleaner'
    config.before(:suite) do
      DatabaseCleaner.strategy = :truncation
      DatabaseCleaner.orm = "mongoid"
    end

    config.before(:each) do
      DatabaseCleaner.clean
    end

    config.include Mongoid::Matchers
    config.include TimeHelpers
    config.include AssetsHelpers
    config.include MustacheHelpers

    config.include Devise::TestHelpers, :type => :controller
    config.include FlashHelpers, :type => :controller
    config.include RedirectHelpers, :type => :controller
  end

  Bluepay.configure do |bluepay|
    bluepay.account_id = "100074088156"
    bluepay.secret_key = "DOOE.QWQ2IHULH7VLHCZNCSGFXFPCA2R"
    bluepay.test = true
  end
end

Spork.each_run do
end
