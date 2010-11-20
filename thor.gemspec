# -*- encoding: utf-8 -*-
require File.expand_path('../lib/thor/version', __FILE__)

Gem::Specification.new do |s|
  s.add_development_dependency("bundler", "~> 1.0")
  s.add_development_dependency("fakeweb", "~> 1.3")
  s.add_development_dependency("rdoc", "~> 2.5")
  s.add_development_dependency("rspec", "~> 2.1")
  s.add_development_dependency("simplecov", "~> 0.3")
  s.name = 'thor'
  s.version = Thor::VERSION.dup
  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.6") if s.respond_to? :required_rubygems_version=
  s.authors = ['Yehuda Katz', 'José Valim']
  s.description = %q{A scripting framework that replaces rake, sake and rubigen}
  s.email = ['ruby-thor@googlegroups.com']
  s.extra_rdoc_files = ['CHANGELOG.rdoc', 'LICENSE', 'README.md', 'Thorfile']
  s.homepage = 'http://yehudakatz.com/2008/05/12/by-thors-hammer/'
  s.rdoc_options = ['--charset=UTF-8']
  s.require_paths = ['lib']
  s.summary = s.description
  s.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
end
