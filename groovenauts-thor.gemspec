# coding: utf-8
lib = File.expand_path("../lib/", __FILE__)
$LOAD_PATH.unshift lib unless $LOAD_PATH.include?(lib)
require "thor/version"

Gem::Specification.new do |spec|
  spec.add_development_dependency "bundler", "~> 1.0"
  # spec.authors = ["Yehuda Katz", "José Valim"]
  spec.authors = ["Takeshi Akima"]
  spec.description = "Thor is a toolkit for building powerful command-line interfaces."
  # spec.email = "ruby-thor@googlegroups.com"
  spec.email = "t-akima@groovenauts.jp"
  spec.executables = %w[thor]
  spec.files = %w[.document groovenauts-thor.gemspec] + Dir['*.md', 'bin/*', 'lib/**/*.rb']
  # spec.homepage = "http://whatisthor.com/"
  spec.homepage = "https://github.com/groovenauts/thor"
  spec.licenses = %w[MIT]
  spec.name = "groovenauts-thor"
  spec.require_paths = %w[lib]
  spec.required_rubygems_version = ">= 1.3.5"
  spec.summary = spec.description
  spec.test_files = Dir.glob("spec/**/*")
  spec.version = Thor::VERSION
end
