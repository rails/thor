# enconding: utf-8
$:.unshift File.expand_path("../lib", __FILE__)

require 'thor/rake_compat'

class Default < Thor
  include Thor::RakeCompat
  Bundler::GemHelper.install_tasks

  desc "build", "Build thor-#{Thor::VERSION}.gem into the pkg directory"
  def build
    Rake::Task["build"].execute
  end

  desc "install", "Build and install thor-#{Thor::VERSION}.gem into system gems"
  def install
    Rake::Task["install"].execute
  end

  desc "release", "Create tag v1.6.2 and build and push twitter-1.6.2.gem to Rubygems"
  def release
    Rake::Task["release"].execute
  end

  desc "spec", "Run RSpec code examples"
  def spec
    exec "rspec -cfs spec"
  end
end
