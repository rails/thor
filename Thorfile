require 'thor/tasks'
require 'rubygems'
require 'thor/rake_compat'

GEM_NAME = 'thor'
EXTRA_RDOC_FILES = ["README.rdoc", "LICENSE", "CHANGELOG.rdoc", "VERSION", "Thorfile"]

class Default < Thor
  include Thor::RakeCompat

  rdoc_task File.dirname(__FILE__), :extra_rdoc_files => EXTRA_RDOC_FILES, :project => GEM_NAME
  spec_task Dir["spec/**/*_spec.rb"]
  rcov_task Dir["spec/**/*_spec.rb"], :exclude => %w(Thorfile)

  begin
    require 'jeweler'
    Jeweler::Tasks.new do |s|
      s.name = GEM_NAME
      s.version = "0.11.4"
      s.rubyforge_project = "thor"
      s.platform = Gem::Platform::RUBY
      s.summary = "A scripting framework that replaces rake, sake and rubigen"
      s.email = "ruby-thor@googlegroups.com"
      s.homepage = "http://yehudakatz.com"
      s.description = "A scripting framework that replaces rake, sake and rubigen"
      s.authors = ['Yehuda Katz', 'José Valim']
      s.has_rdoc = true
      s.extra_rdoc_files = EXTRA_RDOC_FILES
      s.require_path = 'lib'
      s.bindir = "bin"
      s.executables = %w( thor rake2thor )
      s.files = s.extra_rdoc_files + Dir.glob("{bin,lib}/**/*")
    end
  rescue LoadError
    puts "Jeweler, or one of its dependencies, is not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
  end
end
