source "https://rubygems.org"

gem "rake"

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
  gem "rspec", ">= 3"
  gem "rspec-mocks", ">= 3"
  gem "rubocop", ">= 0.19"
  gem "simplecov", ">= 0.13"
  gem "webmock"
end

gem 'did_you_mean'

gemspec
