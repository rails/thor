require File.expand_path(File.dirname(__FILE__) + "/spec_helper")
require 'thor/runner'

describe Thor::Runner do
  describe "#help" do
    it "shows information about Thor::Runner itself" do
      capture(:stdout){ Thor::Runner.start(["help"]) }.must =~ /List the available thor tasks/
    end

    it "shows information about an specific Thor::Runner task" do
      content = capture(:stdout){ Thor::Runner.start(["help", "list"]) }
      content.must =~ /List the available thor tasks/
      content.must_not =~ /help \[TASK\]/
    end

    it "shows information about a specific Thor class" do
      content = capture(:stdout){ Thor::Runner.start(["help", "my_script"]) }
      content.must =~ /zoo\s+# zoo around/m
    end

    it "shows information about an specific task from an specific Thor class" do
      content = capture(:stdout){ Thor::Runner.start(["help", "my_script:zoo"]) }
      content.must =~ /zoo around/
      content.must_not =~ /help \[TASK\]/
    end

    it "shows information about a specific Thor group class" do
      content = capture(:stdout){ Thor::Runner.start(["help", "my_counter"]) }
      content.must =~ /my_counter N \[N\]/
    end

    it "raises error if a class/task cannot be found" do
      content = capture(:stderr){ Thor::Runner.start(["help", "unknown"]) }
      content.must =~ /could not find Thor class or task 'unknown'/
    end
  end

  describe "#start" do
    it "invokes a task from Thor::Runner" do
      ARGV.replace ["list"]
      capture(:stdout){ Thor::Runner.start }.must =~ /my_counter N \[N\]/
    end

    it "invokes a task from a specific Thor class" do
      ARGV.replace ["my_script:zoo"]
      Thor::Runner.start.must be_true
    end

    it "invokes the default task from a specific Thor class if none is specified" do
      ARGV.replace ["my_script"]
      Thor::Runner.start.must == "default task"
    end

    it "forwads arguments to the invoked task" do
      ARGV.replace ["my_script:animal", "horse"]
      Thor::Runner.start.must == ["horse"]
    end

    it "invokes tasks through shortcuts" do
      ARGV.replace ["my_script", "-T", "horse"]
      Thor::Runner.start.must == ["horse"]
    end

    it "invokes a Thor::Group" do
      ARGV.replace ["my_counter", "1", "2", "--third", "3"]
      Thor::Runner.start.must == [1, 2, 3]
    end

    it "raises an error if class/task can't be found" do
      ARGV.replace ["unknown"]
      capture(:stderr){ Thor::Runner.start }.must =~ /could not find Thor class or task 'unknown'/
    end

    it "does not swallow NoMethodErrors that occur inside the called method" do
      ARGV.replace ["my_script:call_unexistent_method"]
      lambda { Thor::Runner.start }.must raise_error(NoMethodError)
    end

    it "does not swallow Thor::Group ArgumentError" do
      ARGV.replace ["whiny_generator"]
      lambda { Thor::Runner.start }.must raise_error(ArgumentError, /Are you sure it has arity equals to 0\?/)
    end

    it "does not swallow Thor ArgumentError" do
      ARGV.replace ["my_script:animal"]
      capture(:stderr) { Thor::Runner.start }.must =~ /'animal' was called incorrectly\. Call as 'my_script:animal TYPE'/
    end
  end

  describe "tasks" do
    before(:each) do
      @location = "#{File.dirname(__FILE__)}/fixtures/task.thor"
      @original_yaml = {
        "random" => {
          :location  => @location,
          :filename  => "4a33b894ffce85d7b412fc1b36f88fe0",
          :constants => ["Amazing"]
        }
      }

      # Stub load and save to avoid thor.yaml from being overwritten
      stub(YAML).load_file { @original_yaml }
      stub(File).exists?(File.join(Thor::Util.thor_root, "thor.yml")){ true }
      stub(File).open(File.join(Thor::Util.thor_root, "thor.yml"), "w")
    end

    describe "list" do
      it "gives a list of the available tasks" do
        ARGV.replace ["list"]
        content = capture(:stdout) { Thor::Runner.start }
        content.must =~ /amazing:describe NAME \[\-\-forcefully\]\s+# say that someone is amazing/m
      end

      it "gives a list of the available Thor::Group classes" do
        ARGV.replace ["list"]
        capture(:stdout) { Thor::Runner.start }.must =~ /my_counter N \[N\]/
      end

      it "can filter a list of the available tasks by --group" do
        ARGV.replace ["list", "--group", "standard"]
        capture(:stdout) { Thor::Runner.start }.must =~ /amazing:describe NAME/
        ARGV.replace []
        capture(:stdout) { Thor::Runner.start }.must_not =~ /my_script:animal TYPE/
        ARGV.replace ["list", "--group", "script"]
        capture(:stdout) { Thor::Runner.start }.must =~ /my_script:animal TYPE/
      end

      it "can skip all filters to show all tasks using --all" do
        ARGV.replace ["list", "--all"]
        content = capture(:stdout) { Thor::Runner.start }
        content.must =~ /amazing:describe NAME/
        content.must =~ /my_script:animal TYPE/
      end

      it "doesn't list superclass tasks in the subclass" do
        ARGV.replace ["list"]
        capture(:stdout) { Thor::Runner.start }.must_not =~ /amazing:help/
      end

      it "presents tasks in the default namespace with an empty namespace" do
        ARGV.replace ["list"]
        capture(:stdout) { Thor::Runner.start }.must =~ /^:test\s+# prints 'test'/m
      end

      it "runs tasks with an empty namespace from the default namespace" do
        ARGV.replace [":test"]
        capture(:stdout) { Thor::Runner.start }.must == "test\n"
      end

      it "updates the yaml file when invoked" do
        capture(:stdout) { Thor::Runner.start(["list"]) }
        @original_yaml["random"][:namespaces].must == ["amazing"]
      end
    end

    describe "update" do
      it "updates existing thor files" do
        mock.instance_of(Thor::Runner).install(@original_yaml["random"][:location]) { true }
        stub(File).delete(File.join(Thor::Util.thor_root, @original_yaml["random"][:filename]))
        silence(:stdout) { Thor::Runner.start(["update", "random"]) }
      end
    end

    describe "uninstall" do
      before(:each) do
        stub.instance_of(Thor::Runner).save_yaml(anything)
        stub(File).delete(anything)
        stub(@original_yaml).delete(anything)
      end

      it "uninstalls existing thor modules" do
        silence(:stdout) { Thor::Runner.start(["uninstall", "random"]) }
      end
    end

    describe "installed" do
      before(:each) do
        stub(Dir).[](anything) { [] }
      end

      it "displays the modules installed in a pretty way" do
        stdout = capture(:stdout) { Thor::Runner.start(["installed"]) }

        stdout.must =~ /random\s*amazing/
        stdout.must =~ /amazing:describe NAME \[\-\-forcefully\]\s+# say that someone is amazing/m
        stdout.must =~ /amazing:hello\s+# say hello/m
      end
    end

    describe "install" do
      it "installs thor files" do
        ARGV.replace ["install", @location]

        # Stubs for the file system interactions
        stub.instance_of(Thor::Base.shell).no? { false }
        stub(FileUtils).mkdir_p
        stub(FileUtils).touch

        mock(File).open(File.join(Thor::Util.thor_root, Digest::MD5.hexdigest(@location + "random")), "w")
        silence(:stdout) { Thor::Runner.start }
      end
    end
  end
end
