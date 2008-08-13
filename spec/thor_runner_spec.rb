require File.dirname(__FILE__) + '/spec_helper'
require "thor/runner"
require "rr"

load File.join(File.dirname(__FILE__), "fixtures", "task.thor")

module MyTasks
  class ThorTask < Thor
    desc "foo", "bar"
    def foo
      "foo"
    end
    
    desc "uhoh", "raises NoMethodError"
    def uhoh
      Object.new.raise_no_method_error_please
    end
  end
end

class Default < Thor
  desc "test", "prints 'test'"
  def test
    puts "test"
  end
end

class Amazing
  desc "hello", "say hello"
  def hello
    puts "Hello"
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
    Thor.subclass_files[File.expand_path(__FILE__)].must == [MyTasks::ThorTask, Default, Amazing, ThorTask2]
  end

  it "tracks a single subclass across multiple files" do
    thorfile = File.join(File.dirname(__FILE__), "fixtures", "task.thor")
    Thor.subclass_files[File.expand_path(thorfile)].must include(Amazing)
    Thor.subclass_files[File.expand_path(__FILE__)].must include(Amazing)
  end
  
  it "tracks its subclasses in an Array" do
    Thor.subclasses.must include(MyTasks::ThorTask)
    Thor.subclasses.must include(ThorTask2)
  end
end

describe Thor::Runner do
  it "can give a list of the available tasks" do
    ARGV.replace ["list"]
    capture(:stdout) { Thor::Runner.start }.must =~ /my_tasks:thor_task:foo +bar/
  end

  it "dosn't list superclass tasks in the subclass" do
    ARGV.replace ["list"]
    capture(:stdout) { Thor::Runner.start }.must_not =~ /my_tasks:thor_task:help/
  end
  
  it "runs tasks from other Thor files" do
    ARGV.replace ["my_tasks:thor_task:foo"]
    Thor::Runner.start.must == "foo"
  end
  
  it "prints an error if a toplevel thor task is not found" do
    ARGV.replace ["hello"]
    capture(:stderr) { Thor::Runner.start }.must =~ /The thor:runner namespace doesn't have a `hello' task/
  end
  
  it "prints an error if the namespace could not be found" do
    ARGV.replace ["hello:goodbye"]
    capture(:stderr) { Thor::Runner.start }.must =~ /There was no available namespace `hello'/
  end  
  
  it "does not swallow NoMethodErrors that occur inside the called method" do
    ARGV.replace ["my_tasks:thor_task:uhoh"]
    proc { Thor::Runner.start }.must raise_error(NoMethodError)
  end

  it "presents tasks in the default namespace with an empty namespace" do
    ARGV.replace ["list"]
    capture(:stdout) { Thor::Runner.start }.must =~ /^:test +prints 'test'/
  end

  it "runs tasks with an empty namespace from the default namespace" do
    ARGV.replace [":test"]
    capture(:stdout) { Thor::Runner.start }.must == "test\n"
  end
end

# describe Thor::Runner, " install" do
#   it "installs thor files" do
#     ARGV.replace ["install", "#{File.dirname(__FILE__)}/fixtures/task.thor"]
# 
#     # Stubs for the file system interactions
#     stub(Kernel).puts
#     stub(Readline).readline { "y" }
#     stub(FileUtils).mkdir_p
#     stub(FileUtils).touch
#     original_yaml = {:random => 
#       {:location => "task.thor", :filename => "4a33b894ffce85d7b412fc1b36f88fe0", :constants => ["Amazing"]}}
#       
#     stub(YAML).load_file { original_yaml }
#     
#     file = mock("File").puts
#     
#     mock(File).open(File.join(Thor::Runner.thor_root, Digest::MD5.hexdigest("#{File.dirname(__FILE__)}/fixtures/task.thor" + "randomness")), "w")
#     mock(File).open(File.join(Thor::Runner.thor_root, "thor.yml"), "w") { yield file }
# 
#     silence(:stdout) { Thor::Runner.start }
#   end
# end

describe Thor::Runner do
  before :each do
    @original_yaml = {"random" => 
      {:location => "#{File.dirname(__FILE__)}/fixtures/task.thor", :filename => "4a33b894ffce85d7b412fc1b36f88fe0", :constants => ["Amazing"]}}
    stub(File).exists? {true}
    stub(YAML).load_file { @original_yaml }
  end
  
  describe " update" do
    it "updates existing thor files" do
      mock.instance_of(Thor::Runner).install(@original_yaml["random"][:location]) {true}
      mock(File).delete(File.join(Thor::Runner.thor_root, @original_yaml["random"][:filename]))
    
      silence(:stdout) { Thor::Runner.start(["update", "random"]) }
    end
  end


  describe " uninstall" do
    it "uninstalls existing thor modules" do
      stub.instance_of(Thor::Runner).save_yaml(anything)
      
      stub(File).delete(anything)
      stub(@original_yaml).delete(anything)
    
      silence(:stdout) { Thor::Runner.start(["uninstall", "random"]) }
    end
  end

  describe " installed" do
    it "displays the modules installed in a pretty way" do
      stub(Dir).[](anything) { [] }
      stdout = capture(:stdout) { Thor::Runner.start(["installed"]) }
      stdout.must =~ /random\s*amazing/
      stdout.must =~ /amazing:describe NAME \[\-\-forcefully\]\s*say that someone is amazing/
      stdout.must =~ /amazing:hello\s*say hello/
    end
  end
end
