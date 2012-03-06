source 'http://rubygems.org'

gem 'rake', '0.8.7'
gem 'rails', '3.1.3'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails', "~> 3.1.0"
  gem 'coffee-rails', "~> 3.1.0"
  gem 'uglifier'
end

gem 'jquery-rails'
gem "bson_ext", "= 1.4.0"
gem "mongo", "= 1.4.0"
gem "mongoid", "~> 2.3.4"
gem "devise", ">= 1.4.7"
gem "devise_invitable", "~> 0.5.6"
gem 'state_machine', :git => 'git://github.com/durran/state_machine.git', :branch => "mongoid-2.3-fixes"
gem 'bluepay', "= 0.1.0", :path => "vendor/gems/bluepay-0.1.0"
gem 'uuid', '~> 2.3.4'

gem "mustache", "~> 0.99.4"
gem "nokogiri", "~> 1.5.0"
gem "haml-rails", "~> 0.3.4"
gem "draper", "~> 0.10.0"
gem 'cells', '~> 3.8.0'

gem "twitter-bootstrap-rails", "~> 1.4.3"
gem 'simple_form', "2.0.0.dev", :git => "git://github.com/plataformatec/simple_form.git"

gem 'carrierwave'
gem 'carrierwave-mongoid', :require => 'carrierwave/mongoid'
gem "rack-raw-upload", "~> 1.0.9"

gem 'resque', :require => "resque/server"

gem 'streamio-ffmpeg'
gem "viddl-rb", "~> 0.5.2"

gem 'unicorn'
gem 'foreman', "0.22.0"

group :development do
  gem 'wirble'
  gem 'capistrano'
  gem "capistrano-ext"
  gem 'ruby-debug19', :require => 'ruby-debug'
  gem 'thin', '~> 1.3.0'
end

group :test do
  gem "rspec", "~> 2.7.0"
  gem "rspec-rails", "~> 2.7.0"
  gem 'email_spec', '~> 1.2.1'
  gem 'rspec-cells', '~> 0.1.2'
  gem "shoulda", "~> 2.11.3"
  gem 'cucumber-rails', '~> 1.2.1'
  gem 'cucumber', '~> 1.1.4'
  gem "database_cleaner", "~> 0.6.7"
  gem "mongoid-rspec", "~> 1.4.4"
  gem "factory_girl_rails", "~> 1.4.0"
  gem "capybara", "~> 1.1.2"
  gem "launchy", "~> 2.0.5"
  gem 'simplecov'
  gem "vcr", "~> 1.11.3"
  gem "webmock", "~> 1.7.10"
  gem 'spork', '~> 0.9.0.rc'
  gem 'timecop', '~> 0.3.5'
end
