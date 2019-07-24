source "https://rubygems.org"

gem "rake", "< 11"

group :development do
  gem "pry"
  platforms :ruby_21 do
    gem "pry-byebug"
  end
  platforms :ruby_20 do
    gem "pry-debugger"
    gem "pry-stack_explorer"
  end
end

group :test do
  gem "childlabor"
  gem "coveralls", ">= 0.8.19"
  gem "mime-types", "~> 1.25", :platforms => [:jruby]
  gem "rest-client", "~> 1.6.0", :platforms => [:jruby]
  gem "rspec", ">= 3"
  gem "rspec-mocks", ">= 3"
  gem "rubocop", ">= 0.19"
  gem "simplecov", ">= 0.13"
  gem "webmock"
end

gem 'did_you_mean'

gemspec
