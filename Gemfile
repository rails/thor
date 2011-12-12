source 'https://rubygems.org'

gemspec

platforms :jruby do
  gem 'jruby-openssl', '~> 0.7'
end

platforms :mri_18 do
  gem 'ruby-debug', '>= 0.10.3'
end

platforms :mri_19 do
  gem 'ruby-debug19'
end

group :development do
  gem 'pry'
end
