# -*- encoding: utf-8 -*-
require File.expand_path('../lib/thor/version', __FILE__)

Gem::Specification.new do |s|
  s.authors = ['Yehuda Katz', 'José Valim']
  s.description = %q{A scripting framework that replaces rake, sake and rubigen}
  s.email = 'ruby-thor@googlegroups.com'
  s.executables = `git ls-files -- bin/*`.split("\n").map{|f| File.basename(f)}
  s.extra_rdoc_files = ['CHANGELOG.rdoc', 'LICENSE.md', 'README.md', 'Thorfile']
  s.files = `git ls-files`.split("\n")
  s.homepage = 'http://whatisthor.com/'
  s.licenses = ['MIT']
  s.name = 'thor'
  s.rdoc_options = ['--charset=UTF-8']
  s.require_paths = ['lib']
  s.required_rubygems_version = Gem::Requirement.new('>= 1.3.6')
  s.summary = s.description
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.version = Thor::VERSION
end
