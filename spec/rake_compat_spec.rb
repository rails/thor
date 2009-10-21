require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'thor/rake_compat'
require 'rake/tasklib'

class RakeTask < Rake::TaskLib
  def initialize
    define
  end
  
  def define
    desc "Say it's cool"
    task :cool do
      puts "COOL"
    end

    namespace :hiper_mega do
      task :super do
        puts "HIPER MEGA SUPER"
      end
    end
  end
end

class ThorTask < Thor
  include Thor::RakeCompat
  RakeTask.new
end

describe Thor::RakeCompat do
  it "sets the rakefile application" do
    ["rake_compat_spec.rb", "Thorfile"].must include(Rake.application.rakefile)
  end

  it "adds rake tasks to thor classes too" do
    task = ThorTask.tasks["cool"]
    task.must be
  end

  it "uses rake tasks descriptions on thor" do
    ThorTask.tasks["cool"].description.must == "Say it's cool"
  end

  it "gets usage from rake tasks name" do
    ThorTask.tasks["cool"].usage.must == "cool"
  end

  it "uses non namespaced name as description if non is available" do
    ThorTask::HiperMega.tasks["super"].description.must == "super"
  end

  it "converts namespaces to classes" do
    ThorTask.const_get(:HiperMega).must == ThorTask::HiperMega
  end

  it "does not add tasks from higher namespaces in lowers namespaces" do
    ThorTask.tasks["super"].must_not be
  end

  it "invoking the thor task invokes the rake task" do
    capture(:stdout) do
      ThorTask.start ["cool"]
    end.must == "COOL\n"

    capture(:stdout) do
      ThorTask::HiperMega.start ["super"]
    end.must == "HIPER MEGA SUPER\n"
  end
end
