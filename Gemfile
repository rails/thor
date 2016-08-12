source 'https://rubygems.org'

gem 'rake', '>= 0.9'
gem 'rdoc', '>= 3.9'

group :development do
  gem 'guard-rspec'
  gem 'pry'
  platforms :ruby_21 do
    gem 'pry-byebug'
  end
  platforms :ruby_19, :ruby_20 do
    gem 'pry-debugger'
    gem 'pry-stack_explorer'
  end
end

group :test do
  gem 'childlabor'
  gem 'coveralls', '>= 0.5.7'
  gem 'addressable', '~> 2.3.6', :platforms => [:ruby_18]
  gem 'webmock', '>= 1.20'
  gem 'mime-types', '~> 1.25', :platforms => [:jruby, :ruby_18]
  gem 'rspec', '>= 3'
  gem 'rspec-mocks', '>= 3'
  gem 'rubocop', '>= 0.19', :platforms => [:ruby_19, :ruby_20, :ruby_21]
  gem 'simplecov', '>= 0.9'
  gem 'rest-client', '~> 1.6.0', :platforms => [:jruby, :ruby_18]
end

gemspec
