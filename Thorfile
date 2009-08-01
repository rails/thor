require 'rubygems'
require 'rubygems/specification'
require 'thor/tasks'

require 'rubygems'
require 'rdoc/rdoc'

GEM = "thor"
GEM_VERSION = "0.11.3"
AUTHOR = "Yehuda Katz"
EMAIL = "wycats@gmail.com"
HOMEPAGE = "http://yehudakatz.com"
SUMMARY = "A scripting framework that replaces rake, sake and rubigen"
PROJECT = "thor"

SPEC = Gem::Specification.new do |s|
  s.name = GEM
  s.version = GEM_VERSION
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  s.extra_rdoc_files = ["README.markdown", "LICENSE", "CHANGELOG.rdoc"]
  s.summary = SUMMARY
  s.description = s.summary
  s.author = AUTHOR
  s.email = EMAIL
  s.homepage = HOMEPAGE
  s.rubyforge_project = PROJECT

  s.require_path = 'lib'
  s.bindir = "bin"
  s.executables = %w( thor rake2thor )
  s.files = s.extra_rdoc_files + %w(Rakefile) + Dir.glob("{bin,lib}/**/*")
end

class Default < Thor
  include Thor::Actions

  # Set up standard Thortasks
  spec_task(Dir["spec/**/*_spec.rb"])
  spec_task(Dir["spec/**/*_spec.rb"], :name => "rcov", :rcov => {:exclude => %w(spec task.thor Thorfile)})
  install_task SPEC

  desc "gemspec", "make a gemspec file"
  def gemspec
    create_file "#{GEM}.gemspec", SPEC.to_ruby, :force => true
  end

  desc "rdoc PATH", "generate rdoc for the path passed as an argument"
  def rdoc(path=File.dirname(__FILE__))
    path   = File.expand_path(path)
    readme = File.join(path, "README.rdoc")

    destination = File.join(Dir.pwd, 'rdoc')
    remove_dir(destination)

    # get all the files to process
    files = Dir.glob("#{path}/lib/**/*.rb")
    files += ["#{path}/README.rdoc", "#{path}/CHANGELOG.rdoc", "#{path}/LICENSE"]

    # rdoc args
    project = File.basename(path)
    arguments = [
      "-t", project,
      "-m", readme,
      "--op", destination
    ]

    say_status :rdoc, "#{project} (#{files.size} files) to: #{destination}"
    RDoc::RDoc.new.document(arguments + files)
  end
end
