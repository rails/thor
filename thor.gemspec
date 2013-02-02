# -*- encoding: utf-8 -*-
require File.expand_path('../lib/thor/version', __FILE__)

Gem::Specification.new do |spec|
  spec.add_development_dependency 'bundler', '~> 1.0'
  spec.authors = ['Yehuda Katz', 'José Valim']
  spec.description = %q{A scripting framework that replaces rake, sake and rubigen}
  spec.email = 'ruby-thor@googlegroups.com'
  spec.executables = `git ls-files -- bin/*`.split("\n").map{|f| File.basename(f)}
  spec.extra_rdoc_files = ['CHANGELOG.rdoc', 'LICENSE.md', 'README.md', 'Thorfile']
  spec.files = `git ls-files`.split("\n")
  spec.homepage = 'http://whatisthor.com/'
  spec.licenses = ['MIT']
  spec.name = 'thor'
  spec.require_paths = ['lib']
  spec.required_rubygems_version = Gem::Requirement.new('>= 1.3.6')
  spec.summary = spec.description
  spec.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  spec.version = Thor::VERSION
end
