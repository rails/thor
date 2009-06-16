require 'rubygems'
require 'rubygems/specification'
require 'thor/tasks'

GEM = "thor"
GEM_VERSION = "0.10.3"
AUTHOR = "Yehuda Katz"
EMAIL = "wycats@gmail.com"
HOMEPAGE = "http://yehudakatz.com"
SUMMARY = "A gem that maps options to a class"
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
  s.files = s.extra_rdoc_files + %w(Rakefile) + Dir.glob("{bin,lib,specs}/**/*")
end

class Default < Thor
  # Set up standard Thortasks
  spec_task(Dir["spec/**/*_spec.rb"])
  spec_task(Dir["spec/**/*_spec.rb"], :name => "rcov", :rcov =>
    {:exclude => %w(spec /Library /Users task.thor lib/getopt.rb)})
  install_task SPEC

  desc "gemspec", "make a gemspec file"
  def gemspec
    File.open("#{GEM}.gemspec", "w") do |file|
      file.puts SPEC.to_ruby
    end
  end
end
