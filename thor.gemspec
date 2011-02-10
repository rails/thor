# -*- encoding: utf-8 -*-
require File.expand_path('../lib/thor/version', __FILE__)

extra_rdoc_files = ['CHANGELOG.rdoc', 'LICENSE', 'README.md', 'Thorfile']

Gem::Specification.new do |s|
  s.name = 'thor'
  s.version = Thor::VERSION.dup
  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.6") if s.respond_to? :required_rubygems_version=
  s.authors = ['Yehuda Katz', 'José Valim']
  s.description = %q{A scripting framework that replaces rake, sake and rubigen}
  s.email = ['ruby-thor@googlegroups.com']
  s.extra_rdoc_files = extra_rdoc_files
  s.homepage = 'http://github.com/wycats/thor'
  s.rdoc_options = ['--charset=UTF-8']
  s.require_paths = ['lib']
  s.summary = s.description
  s.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.files = `git ls-files -- {bin,lib,spec}/*`.split("\n") + extra_rdoc_files
  s.test_files = `git ls-files -- {spec}/*`.split("\n")

  s.add_development_dependency("bundler", "~> 1.0")
  s.add_development_dependency("fakeweb", "~> 1.3")
  s.add_development_dependency("rdoc", "~> 2.5")
  s.add_development_dependency("rake", ">= 0.8")
  s.add_development_dependency("rspec", "~> 2.3")
  s.add_development_dependency("simplecov", "~> 0.4")
end
