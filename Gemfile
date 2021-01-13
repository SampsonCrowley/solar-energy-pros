source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "2.7.2"

# core gems
gem "rails", "~> 6.0.3", ">= 6.0.3.4"
gem "pg", "~> 1.1", ">= 1.1.2"
gem "puma", "~> 4.3", ">= 4.3.3"
gem "webpacker", "~> 4.0"
gem "turbolinks", "~> 5"
gem "jbuilder", "~> 2.7"
gem "redis", "~> 4.2.1"
gem "coerce_boolean", "~> 0.1"

# extension gems
# gem "aasm", "~> 5.0", ">= 5.0.1"
gem "redis-namespace", "~> 1.8.0"
gem "associate_jsonb", "~> 0.0", ">= 0.0.10"
gem "store_as_int", "~> 0.0", ">= 0.0.19"
gem "csv_rb", "~> 6.0.3", ">= 6.0.3.1"
gem "image_processing", "~> 1.12"
# gem "braintree", "~> 2.90", ">= 2.90.0"
# gem "browser", "~> 2.5", ">= 2.5.3"
gem "logidze", "~> 0.12.0"
gem "inky-rb", "~> 1.3", require: "inky"
gem "premailer-rails", "~> 1.11"
gem "sidekiq", "~> 6.1"

# file storage gems
gem "aws-sdk-s3", ">= 1.30.1", require: false

# security handling gems
gem "rbnacl", "~> 7.1"
gem "nacl_password", "~> 0.1"
gem "secure_web_token", "~> 0.1"
gem "openssl", "~> 2.1"
gem "pundit", "~> 2.1"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", ">= 1.4.2", require: false

group :development, :test do
  gem "tiny_fake_redis", "~> 0.1", ">= 0.1.0"

  # Call "byebug" anywhere in the code to stop execution and get a debugger console
  gem "byebug", platforms: [:mri, :mingw, :x64_mingw]
end

group :development do
  # Access an interactive console on exception pages or by calling "console" anywhere in the code.
  gem "web-console", ">= 3.3.0"
  gem "listen", "~> 3.2"
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem "spring"
  gem "spring-watcher-listen", "~> 2.0.0"
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem "capybara", ">= 2.15"
  gem "selenium-webdriver"
  # Easy installation and use of web drivers to run system tests with browsers
  gem "webdrivers"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
# gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]

gem "http_accept_language", "~> 2.1"
