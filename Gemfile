source "https://rubygems.org"

gem "rake"

group :development do
  gem "pry"
  gem "pry-byebug"
end

group :test do
  gem "childlabor"
  gem 'coveralls_reborn', '~> 0.23.1', :require => false if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("2.6.0")
  gem "rspec", ">= 3.2"
  gem "rspec-mocks", ">= 3"
  gem "simplecov", ">= 0.13"
  gem "webmock"
end

gemspec
