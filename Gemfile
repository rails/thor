source 'http://rubygems.org'

gemspec

platforms :mri_18 do
  gem "ruby-debug", ">= 0.10.3"
  gem "linecache", "<= 0.45"
end

platforms :mri_19 do
  gem "ruby-debug19"
end

group :development do
  gem "pry"
  gem "cucumber"
  gem "aruba"
end
