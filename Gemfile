source "https://rubygems.org"

gem "rake", "< 11"
gem "rdoc", "~> 4.2.2" # This is to support Ruby 1.8 and 1.9

group :development do
  gem "pry"
  platforms :ruby_21 do
    gem "pry-byebug"
  end
  platforms :ruby_19, :ruby_20 do
    gem "pry-debugger"
    gem "pry-stack_explorer"
  end
end

group :test do
  gem "addressable", "~> 2.3.6", :platforms => [:ruby_18]
  gem "childlabor"
  gem "coveralls", ">= 0.5.7"
  gem "json", "< 2" # This is to support Ruby 1.8 and 1.9
  gem "mime-types", "~> 1.25", :platforms => [:jruby, :ruby_18]
  gem "rest-client", "~> 1.6.0", :platforms => [:jruby, :ruby_18]
  gem "rspec", ">= 3"
  gem "rspec-mocks", ">= 3"
  gem "rubocop", ">= 0.19", :platforms => [:ruby_20, :ruby_21, :ruby_22, :ruby_23, :ruby_24]
  gem "simplecov", ">= 0.9"
  gem "term-ansicolor", "~> 1.3.2" # This is to support Ruby 1.8 and 1.9
  gem "tins", "< 1.7" # This is to support Ruby 1.8 and 1.9
  if RUBY_VERSION < "1.9.3"
    gem "webmock", ">= 1.20", "< 2" # This is to support Ruby 1.8 and 1.9.2
  else
    gem "webmock"
  end
end

gemspec
