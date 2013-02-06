# coding: utf-8
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
require 'thor/version'

Gem::Specification.new do |spec|
  spec.add_development_dependency 'bundler', '~> 1.0'
  spec.authors = ['Yehuda Katz', 'José Valim']
  spec.description = %q{A scripting framework that replaces rake, sake and rubigen}
  spec.email = 'ruby-thor@googlegroups.com'
  spec.executables = %w(thor)
  spec.files = %w(.document CHANGELOG.md LICENSE.md README.md Thorfile thor.gemspec)
  spec.files += Dir.glob("bin/**/*")
  spec.files += Dir.glob("lib/**/*.rb")
  spec.files += Dir.glob("spec/**/*")
  spec.homepage = 'http://whatisthor.com/'
  spec.licenses = ['MIT']
  spec.name = 'thor'
  spec.require_paths = ['lib']
  spec.required_rubygems_version = '>= 1.3.6'
  spec.summary = spec.description
  spec.test_files = Dir.glob("spec/**/*")
  spec.version = Thor::VERSION
end
