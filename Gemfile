source 'https://rubygems.org'

gem 'rake', '>= 0.9'
gem 'rdoc', '>= 3.9'

group :development do
  gem 'guard-rspec'
  gem 'pry'
  gem 'pry-rescue'
  platforms :ruby_19, :ruby_20 do
    gem 'pry-debugger'
    gem 'pry-stack_explorer'
  end
end

group :test do
  gem 'childlabor'
  gem 'coveralls', '>=0.5.7', :require => false
  # mime-types is required indirectly by coveralls
  # needs to be < 2.0 to work with Ruby 1.8.7
  gem 'mime-types', '~> 1.25', :platforms => [:jruby, :ruby_18]
  gem 'fakeweb', '>= 1.3'
  gem 'rspec', '>= 2.14'
  gem 'rspec-mocks', '>= 2.12.2'
  gem 'rubocop', '>= 0.16', :platforms => [:ruby_19, :ruby_20, :ruby_21]
  gem 'simplecov', :require => false
end

platform :rbx do
  gem 'rubinius-coverage'
  gem 'rubysl'
end

gemspec
