require File.dirname(__FILE__) + '/spec_helper'
require "thor"

load File.join("#{File.dirname(__FILE__)}", "..", "bin", "thor")

class StdOutCapturer
  attr_reader :output

  def initialize
    @output = ""
  end

  def self.call_func
    begin
      old_out = $stdout
      output = new
      $stdout = output
      yield
    ensure
      $stdout = old_out
    end
    output.output
  end

  def write(s)
    @output += s
  end
end

module MyTasks
  class ThorTask < Thor
    desc "foo", "bar"
    def foo
      "foo"
    end
  end
end

class ThorTask2 < Thor
end

describe Thor::Util do
  it "knows how to convert class names into thor names" do
    Thor::Util.constant_to_thor_path("FooBar::BarBaz::BazBat").must == "foo_bar:bar_baz:baz_bat"
  end
  
  it "knows how to convert a thor name to a constant" do
    Thor::Util.constant_from_thor_path("my_tasks:thor_task").must == MyTasks::ThorTask
  end
end

describe Thor do
  it "tracks its subclasses, grouped by the files they come from" do
    Thor.subclass_files[File.expand_path(__FILE__)].must == [MyTasks::ThorTask, ThorTask2]
  end
  
  it "tracks its subclasses in an Array" do
    Thor.subclasses.must include(MyTasks::ThorTask)
    Thor.subclasses.must include(ThorTask2)
  end
end

describe Thor::Runner do
  it "can give a list of the available tasks" do
    ARGV.replace ["list"]
    stdout_from { Thor::Runner.start }.must =~ /my_tasks:thor_task:foo +bar/
  end
  
  it "runs tasks from other Thor files" do
    ARGV.replace ["my_tasks:thor_task:foo"]
    Thor::Runner.start.must == "foo"
  end
  
  it "prints an error if a thor task is not namespaced" do
    ARGV.replace ["hello"]
    stdout_from { Thor::Runner.start }.must =~ /Thor tasks must contain a :/
  end
  
  it "prints an error if the namespace could not be found" do
    ARGV.replace ["hello:goodbye"]
    stdout_from { Thor::Runner.start }.must =~ /There was no available namespace `hello'/
  end  
end

describe Thor::Runner, " install" do
  it "installs thor files" do
    ARGV.replace ["install", "#{File.dirname(__FILE__)}/fixtures/task.thor"]

    Kernel.stub!(:puts)
    Readline.stub!(:readline).and_return("y")
    FileUtils.stub!(:mkdir_p)
    FileUtils.stub!(:touch)
    original_yaml = {:random => 
      {:location => "task.thor", :filename => "4a33b894ffce85d7b412fc1b36f88fe0", :constants => ["Amazing"]}}
    YAML.stub!(:load_file).and_return(original_yaml)
    
    file = mock("File")
    file.should_receive(:puts)
    
    File.should_receive(:open).with(File.join(ENV["HOME"], ".thor", Digest::MD5.hexdigest("#{File.dirname(__FILE__)}/fixtures/task.thor" + "randomness")) + ".thor", "w")
    File.should_receive(:open).with(File.join(ENV["HOME"], ".thor", "thor.yml"), "w").once.and_yield(file)
    
    Thor::Runner.start    
  end
end