# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{thor}
  s.version = "0.10.24"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Yehuda Katz"]
  s.date = %q{2009-07-04}
  s.description = %q{A scripting framework that replaces rake, sake and rubigen}
  s.email = %q{wycats@gmail.com}
  s.executables = ["thor", "rake2thor"]
  s.extra_rdoc_files = ["README.markdown", "LICENSE", "CHANGELOG.rdoc"]
  s.files = ["README.markdown", "LICENSE", "CHANGELOG.rdoc", "Rakefile", "bin/rake2thor", "bin/thor", "lib/thor.rb", "lib/thor", "lib/thor/error.rb", "lib/thor/base.rb", "lib/thor/group.rb", "lib/thor/actions", "lib/thor/actions/templater.rb", "lib/thor/actions/copy_file.rb", "lib/thor/actions/inject_into_file.rb", "lib/thor/actions/directory.rb", "lib/thor/actions/template.rb", "lib/thor/actions/get.rb", "lib/thor/actions/create_file.rb", "lib/thor/actions/empty_directory.rb", "lib/thor/util.rb", "lib/thor/runner.rb", "lib/thor/actions.rb", "lib/thor/parser.rb", "lib/thor/shell", "lib/thor/shell/basic.rb", "lib/thor/shell/color.rb", "lib/thor/invocation.rb", "lib/thor/parser", "lib/thor/parser/argument.rb", "lib/thor/parser/option.rb", "lib/thor/parser/options.rb", "lib/thor/parser/arguments.rb", "lib/thor/tasks.rb", "lib/thor/core_ext", "lib/thor/core_ext/hash_with_indifferent_access.rb", "lib/thor/core_ext/ordered_hash.rb", "lib/thor/tasks", "lib/thor/tasks/install.rb", "lib/thor/tasks/spec.rb", "lib/thor/tasks/package.rb", "lib/thor/shell.rb", "lib/thor/task.rb", "spec/sandbox", "spec/actions", "spec/actions/directory_spec.rb", "spec/actions/empty_directory_spec.rb", "spec/actions/template_spec.rb", "spec/actions/copy_file_spec.rb", "spec/actions/get_spec.rb", "spec/actions/create_file_spec.rb", "spec/actions/inject_into_file_spec.rb", "spec/actions/templater_spec.rb", "spec/shell_spec.rb", "spec/invocation_spec.rb", "spec/base_spec.rb", "spec/task_spec.rb", "spec/spec_helper.rb", "spec/actions_spec.rb", "spec/shell", "spec/shell/basic_spec.rb", "spec/shell/color_spec.rb", "spec/group_spec.rb", "spec/thor_spec.rb", "spec/fixtures", "spec/fixtures/script.thor", "spec/fixtures/invoke.thor", "spec/fixtures/doc", "spec/fixtures/doc/README", "spec/fixtures/doc/%file_name%.rb.tt", "spec/fixtures/doc/config.rb", "spec/fixtures/doc/components", "spec/fixtures/group.thor", "spec/fixtures/task.thor", "spec/spec.opts", "spec/util_spec.rb", "spec/parser", "spec/parser/argument_spec.rb", "spec/parser/option_spec.rb", "spec/parser/options_spec.rb", "spec/parser/arguments_spec.rb", "spec/runner_spec.rb", "spec/core_ext", "spec/core_ext/ordered_hash_spec.rb", "spec/core_ext/hash_with_indifferent_access_spec.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://yehudakatz.com}
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{thor}
  s.rubygems_version = %q{1.3.2}
  s.summary = %q{A scripting framework that replaces rake, sake and rubigen}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
