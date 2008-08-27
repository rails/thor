Gem::Specification.new do |s|
  s.name = %q{thor}
  s.version = "0.9.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Yehuda Katz"]
  s.date = %q{2008-08-27}
  s.description = %q{A gem that maps options to a class}
  s.email = %q{wycats@gmail.com}
  s.executables = ["thor", "rake2thor"]
  s.extra_rdoc_files = ["README.markdown", "CHANGELOG.rdoc", "LICENSE"]
  s.files = ["README.markdown", "LICENSE", "CHANGELOG.rdoc", "Rakefile", "bin/rake2thor", "bin/thor", "lib/thor", "lib/thor/error.rb", "lib/thor/options.rb", "lib/thor/ordered_hash.rb", "lib/thor/runner.rb", "lib/thor/task.rb", "lib/thor/task_hash.rb", "lib/thor/tasks", "lib/thor/tasks/package.rb", "lib/thor/tasks.rb", "lib/thor/util.rb", "lib/thor.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://yehudakatz.com}
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{thor}
  s.rubygems_version = %q{1.2.0}
  s.summary = %q{A gem that maps options to a class}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if current_version >= 3 then
    else
    end
  else
  end
end
