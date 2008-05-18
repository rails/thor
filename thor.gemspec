Gem::Specification.new do |s|
  s.name = %q{thor}
  s.version = "0.9.2"

  s.specification_version = 2 if s.respond_to? :specification_version=

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Yehuda Katz"]
  s.date = %q{2008-05-17}
  s.description = %q{A gem that maps options to a class}
  s.email = %q{wycats@gmail.com}
  s.executables = ["thor", "rake2thor"]
  s.extra_rdoc_files = ["README.markdown", "LICENSE"]
  s.files = ["LICENSE", "README.markdown", "Rakefile", "bin/rake2thor", "bin/thor", "lib/thor.rb", "lib/thor", "lib/thor/util.rb", "lib/thor/task.rb", "lib/thor/error.rb", "lib/thor/ordered_hash.rb", "lib/thor/task_hash.rb", "lib/thor/tasks.rb", "lib/getopt.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://yehudakatz.com}
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{thor}
  s.rubygems_version = %q{1.1.1}
  s.summary = %q{A gem that maps options to a class}
end
