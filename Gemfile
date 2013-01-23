source 'https://rubygems.org'

gemspec

platforms :mri_18 do
  gem 'ruby-debug', '>= 0.10.3'
end

platforms :mri_19 do
  gem 'debugger' if RUBY_VERSION < '2.0'
end

group :development do
  gem 'childlabor'
  gem 'fakeweb', '~> 1.3'
  gem 'pry'
  gem 'rake', '~> 0.9'
  gem 'rdoc', '~> 3.9'
  gem 'rspec', '~> 2.11'
  gem 'rspec-mocks'
  gem 'simplecov'
end
