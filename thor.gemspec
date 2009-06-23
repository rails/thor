# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{thor}
  s.version = "0.10.11"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Yehuda Katz"]
  s.date = %q{2009-06-23}
  s.description = %q{A gem that maps options to a class}
  s.email = %q{wycats@gmail.com}
  s.executables = ["thor", "rake2thor"]
  s.extra_rdoc_files = ["README.markdown", "LICENSE", "CHANGELOG.rdoc"]
  s.files = ["README.markdown", "LICENSE", "CHANGELOG.rdoc", "Rakefile", "bin/rake2thor", "bin/thor", "lib/thor.rb", "lib/thor", "lib/thor/error.rb", "lib/thor/base.rb", "lib/thor/group.rb", "lib/thor/actions", "lib/thor/actions/templater.rb", "lib/thor/actions/copy_file.rb", "lib/thor/actions/inject_into_file.rb", "lib/thor/actions/directory.rb", "lib/thor/actions/template.rb", "lib/thor/actions/get.rb", "lib/thor/actions/create_file.rb", "lib/thor/actions/empty_directory.rb", "lib/thor/util.rb", "lib/thor/runner.rb", "lib/thor/actions.rb", "lib/thor/option.rb", "lib/thor/options.rb", "lib/thor/shell", "lib/thor/shell/basic.rb", "lib/thor/invocation.rb", "lib/thor/tasks.rb", "lib/thor/core_ext", "lib/thor/core_ext/hash_with_indifferent_access.rb", "lib/thor/core_ext/ordered_hash.rb", "lib/thor/tasks", "lib/thor/tasks/install.rb", "lib/thor/tasks/spec.rb", "lib/thor/tasks/package.rb", "lib/thor/shell.rb", "lib/thor/task.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://yehudakatz.com}
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{thor}
  s.rubygems_version = %q{1.3.2}
  s.summary = %q{A gem that maps options to a class}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
