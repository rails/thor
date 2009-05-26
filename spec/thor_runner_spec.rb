#require File.expand_path(File.dirname(__FILE__) + "/spec_helper")
#require 'thor/runner'
#require 'rr'

#module MyTasks
#  class ThorTask < Thor
#    desc "foo", "bar"
#    def foo
#      "foo"
#    end
#    
#    desc "uhoh", "raises NoMethodError"
#    def uhoh
#      Object.new.raise_no_method_error_please
#    end
#  end
#  
#  class AdvancedTask < Thor
#    group :advanced
#    
#    desc "zoo", "zip"
#    def zoo
#      "zip"
#    end
#  end  
#end

#module Thor::Tasks
#  class Default < Thor
#    desc "test", "prints 'test'"
#    def test
#      puts "test"
#    end
#  end
#end



#class ThorTask2 < Thor
#end

#describe Thor::Runner do
#  it "can give a list of the available tasks" do
#    ARGV.replace ["list"]
#    capture(:stdout) { Thor::Runner.start }.must =~ /my_tasks:thor_task:foo +bar/
#  end
#  
#  xit "can filter a list of the available tasks by --group" do
#    ARGV.replace ["list", "--group", "standard"]
#    capture(:stdout) { Thor::Runner.start }.must =~ /my_tasks:thor_task:foo +bar/
#    capture(:stdout) { Thor::Runner.start }.must_not =~ /my_tasks:advanced_task:zoo +zip/
#    ARGV.replace ["list", "--group", "advanced"]
#    capture(:stdout) { Thor::Runner.start }.must =~ /my_tasks:advanced_task:zoo +zip/
#  end
#  
#  xit "can skip all filters to show all tasks using --all" do
#    ARGV.replace ["list", "--all"]
#    capture(:stdout) { Thor::Runner.start }.must =~ /my_tasks:thor_task:foo +bar/
#    capture(:stdout) { Thor::Runner.start }.must =~ /my_tasks:advanced_task:zoo +zip/
#  end

#  it "doesn't list superclass tasks in the subclass" do
#    ARGV.replace ["list"]
#    capture(:stdout) { Thor::Runner.start }.must_not =~ /my_tasks:thor_task:help/
#  end
#  
#  it "runs tasks from other Thor files" do
#    ARGV.replace ["my_tasks:thor_task:foo"]
#    Thor::Runner.start.must == "foo"
#  end
#  
#  it "prints an error if a toplevel thor task is not found" do
#    ARGV.replace ["hello"]
#    capture(:stderr) { Thor::Runner.start }.must =~ /The thor:runner namespace doesn't have a `hello' task/
#  end
#  
#  it "prints an error if the namespace could not be found" do
#    ARGV.replace ["hello:goodbye"]
#    capture(:stderr) { Thor::Runner.start }.must =~ /There was no available namespace `hello'/
#  end  
#  
#  it "does not swallow NoMethodErrors that occur inside the called method" do
#    ARGV.replace ["my_tasks:thor_task:uhoh"]
#    proc { Thor::Runner.start }.must raise_error(NoMethodError)
#  end

#  it "presents tasks in the default namespace with an empty namespace" do
#    ARGV.replace ["list"]
#    capture(:stdout) { Thor::Runner.start }.must =~ /^:test +prints 'test'/
#  end

#  it "runs tasks with an empty namespace from the default namespace" do
#    ARGV.replace [":test"]
#    capture(:stdout) { Thor::Runner.start }.must == "test\n"
#  end
#end

## describe Thor::Runner, " install" do
##   it "installs thor files" do
##     ARGV.replace ["install", "#{File.dirname(__FILE__)}/fixtures/task.thor"]
## 
##     # Stubs for the file system interactions
##     stub(Kernel).puts
##     stub(Readline).readline { "y" }
##     stub(FileUtils).mkdir_p
##     stub(FileUtils).touch
##     original_yaml = {:random => 
##       {:location => "task.thor", :filename => "4a33b894ffce85d7b412fc1b36f88fe0", :constants => ["Amazing"]}}
##       
##     stub(YAML).load_file { original_yaml }
##     
##     file = mock("File").puts
##     
##     mock(File).open(File.join(Thor::Runner.thor_root, Digest::MD5.hexdigest("#{File.dirname(__FILE__)}/fixtures/task.thor" + "randomness")), "w")
##     mock(File).open(File.join(Thor::Runner.thor_root, "thor.yml"), "w") { yield file }
## 
##     silence(:stdout) { Thor::Runner.start }
##   end
## end

#describe Thor::Runner do
#  before :each do
#    @original_yaml = {
#      "random" => {
#        :location  => "#{File.dirname(__FILE__)}/fixtures/task.thor",
#        :filename  => "4a33b894ffce85d7b412fc1b36f88fe0",
#        :constants => ["Amazing"]
#      }
#    }

#    stub(File).exists? { true }
#    stub(YAML).load_file { @original_yaml }
#  end
#  
#  describe "update" do
#    it "updates existing thor files" do
#      mock.instance_of(Thor::Runner).install(@original_yaml["random"][:location]) { true }
#      mock(File).delete(File.join(Thor::Runner.thor_root, @original_yaml["random"][:filename]))
#    
#      silence(:stdout) { Thor::Runner.start(["update", "random"]) }
#    end
#  end

#  describe "uninstall" do
#    before(:each) do
#      stub.instance_of(Thor::Runner).save_yaml(anything)
#      
#      stub(File).delete(anything)
#      stub(@original_yaml).delete(anything)
#    end

#    it "uninstalls existing thor modules" do
#      silence(:stdout) { Thor::Runner.start(["uninstall", "random"]) }
#    end
#  end

#  describe "installed" do
#    before(:each) do
#      stub(Dir).[](anything) { [] }
#    end

#    it "displays the modules installed in a pretty way" do
#      stdout = capture(:stdout) { Thor::Runner.start(["installed"]) }

#      stdout.must =~ /random\s*amazing/
#      stdout.must =~ /amazing:describe NAME \[\-\-forcefully\]\s*say that someone is amazing/
#      stdout.must =~ /amazing:hello\s*say hello/
#    end
#  end
#end
