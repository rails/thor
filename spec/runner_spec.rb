require 'helper'
require 'thor/runner'

describe Thor::Runner do
  def when_no_thorfiles_exist
    old_dir = Dir.pwd
    Dir.chdir '..'
    delete = Thor::Base.subclasses.select {|e| e.namespace == 'default' }
    delete.each {|e| Thor::Base.subclasses.delete e }
    yield
    Thor::Base.subclasses.concat delete
    Dir.chdir old_dir
  end

  describe "#help" do
    it "shows information about Thor::Runner itself" do
      expect(capture(:stdout) { Thor::Runner.start(["help"]) }).to match(/List the available thor commands/)
    end

    it "shows information about a specific Thor::Runner command" do
      content = capture(:stdout) { Thor::Runner.start(["help", "list"]) }
      expect(content).to match(/List the available thor commands/)
      expect(content).not_to match(/help \[COMMAND\]/)
    end

    it "shows information about a specific Thor class" do
      content = capture(:stdout) { Thor::Runner.start(["help", "my_script"]) }
      expect(content).to match(/zoo\s+# zoo around/m)
    end

    it "shows information about an specific command from an specific Thor class" do
      content = capture(:stdout) { Thor::Runner.start(["help", "my_script:zoo"]) }
      expect(content).to match(/zoo around/)
      expect(content).not_to match(/help \[COMMAND\]/)
    end

    it "shows information about a specific Thor group class" do
      content = capture(:stdout) { Thor::Runner.start(["help", "my_counter"]) }
      expect(content).to match(/my_counter N/)
    end

    it "raises error if a class/command cannot be found" do
      content = capture(:stderr){ Thor::Runner.start(["help", "unknown"]) }
      expect(content.strip).to eq('Could not find command "unknown" in "default" namespace.')
    end

    it "raises error if a class/command cannot be found for a setup without thorfiles" do
      when_no_thorfiles_exist do
        Thor::Runner.should_receive :exit
        content = capture(:stderr){ Thor::Runner.start(["help", "unknown"]) }
        expect(content.strip).to eq('Could not find command "unknown".')
      end
    end
  end

  describe "#start" do
    it "invokes a command from Thor::Runner" do
      ARGV.replace ["list"]
      expect(capture(:stdout) { Thor::Runner.start }).to match(/my_counter N/)
    end

    it "invokes a command from a specific Thor class" do
      ARGV.replace ["my_script:zoo"]
      expect(Thor::Runner.start).to be_true
    end

    it "invokes the default command from a specific Thor class if none is specified" do
      ARGV.replace ["my_script"]
      expect(Thor::Runner.start).to eq("default command")
    end

    it "forwads arguments to the invoked command" do
      ARGV.replace ["my_script:animal", "horse"]
      expect(Thor::Runner.start).to eq(["horse"])
    end

    it "invokes commands through shortcuts" do
      ARGV.replace ["my_script", "-T", "horse"]
      expect(Thor::Runner.start).to eq(["horse"])
    end

    it "invokes a Thor::Group" do
      ARGV.replace ["my_counter", "1", "2", "--third", "3"]
      expect(Thor::Runner.start).to eq([1, 2, 3, nil, nil, nil])
    end

    it "raises an error if class/command can't be found" do
      ARGV.replace ["unknown"]
      content = capture(:stderr){ Thor::Runner.start }
      expect(content.strip).to eq('Could not find command "unknown" in "default" namespace.')
    end

    it "raises an error if class/command can't be found in a setup without thorfiles" do
      when_no_thorfiles_exist do
        ARGV.replace ["unknown"]
        Thor::Runner.should_receive :exit
        content = capture(:stderr){ Thor::Runner.start }
        expect(content.strip).to eq('Could not find command "unknown".')
      end
    end

    it "does not swallow NoMethodErrors that occur inside the called method" do
      ARGV.replace ["my_script:call_unexistent_method"]
      expect{ Thor::Runner.start }.to raise_error(NoMethodError)
    end

    it "does not swallow Thor::Group InvocationError" do
      ARGV.replace ["whiny_generator"]
      expect{ Thor::Runner.start }.to raise_error(ArgumentError, /thor wrong_arity takes 1 argument, but it should not/)
    end

    it "does not swallow Thor InvocationError" do
      ARGV.replace ["my_script:animal"]
      content = capture(:stderr) { Thor::Runner.start }
      expect(content.strip).to eq(%Q'ERROR: thor animal was called with no arguments\nUsage: "thor my_script:animal TYPE".')
    end
  end

  describe "commands" do
    before do
      @location = "#{File.dirname(__FILE__)}/fixtures/command.thor"
      @original_yaml = {
        "random" => {
          :location  => @location,
          :filename  => "4a33b894ffce85d7b412fc1b36f88fe0",
          :namespaces => ["amazing"]
        }
      }

      root_file = File.join(Thor::Util.thor_root, "thor.yml")

      # Stub load and save to avoid thor.yaml from being overwritten
      YAML.stub!(:load_file).and_return(@original_yaml)
      File.stub!(:exists?).with(root_file).and_return(true)
      File.stub!(:open).with(root_file, "w")
    end

    describe "list" do
      it "gives a list of the available commands" do
        ARGV.replace ["list"]
        content = capture(:stdout) { Thor::Runner.start }
        expect(content).to match(/amazing:describe NAME\s+# say that someone is amazing/m)
      end

      it "gives a list of the available Thor::Group classes" do
        ARGV.replace ["list"]
        expect(capture(:stdout) { Thor::Runner.start }).to match(/my_counter N/)
      end

      it "can filter a list of the available commands by --group" do
        ARGV.replace ["list", "--group", "standard"]
        expect(capture(:stdout) { Thor::Runner.start }).to match(/amazing:describe NAME/)
        ARGV.replace []
        expect(capture(:stdout) { Thor::Runner.start }).not_to match(/my_script:animal TYPE/)
        ARGV.replace ["list", "--group", "script"]
        expect(capture(:stdout) { Thor::Runner.start }).to match(/my_script:animal TYPE/)
      end

      it "can skip all filters to show all commands using --all" do
        ARGV.replace ["list", "--all"]
        content = capture(:stdout) { Thor::Runner.start }
        expect(content).to match(/amazing:describe NAME/)
        expect(content).to match(/my_script:animal TYPE/)
      end

      it "doesn't list superclass commands in the subclass" do
        ARGV.replace ["list"]
        expect(capture(:stdout) { Thor::Runner.start }).not_to match(/amazing:help/)
      end

      it "presents commands in the default namespace with an empty namespace" do
        ARGV.replace ["list"]
        expect(capture(:stdout) { Thor::Runner.start }).to match(/^thor :cow\s+# prints 'moo'/m)
      end

      it "runs commands with an empty namespace from the default namespace" do
        ARGV.replace [":command_conflict"]
        expect(capture(:stdout) { Thor::Runner.start }).to eq("command\n")
      end

      it "runs groups even when there is a command with the same name" do
        ARGV.replace ["command_conflict"]
        expect(capture(:stdout) { Thor::Runner.start }).to eq("group\n")
      end

      it "runs commands with no colon in the default namespace" do
        ARGV.replace ["cow"]
        expect(capture(:stdout) { Thor::Runner.start }).to eq("moo\n")
      end
    end

    describe "uninstall" do
      before do
        path = File.join(Thor::Util.thor_root, @original_yaml["random"][:filename])
        FileUtils.should_receive(:rm_rf).with(path)
      end

      it "uninstalls existing thor modules" do
        silence(:stdout) { Thor::Runner.start(["uninstall", "random"]) }
      end
    end

    describe "installed" do
      before do
        Dir.should_receive(:[]).and_return([])
      end

      it "displays the modules installed in a pretty way" do
        stdout = capture(:stdout) { Thor::Runner.start(["installed"]) }
        expect(stdout).to match(/random\s*amazing/)
        expect(stdout).to match(/amazing:describe NAME\s+# say that someone is amazing/m)
      end
    end

    describe "install/update" do
      before do
        FileUtils.stub!(:mkdir_p)
        FileUtils.stub!(:touch)
        $stdin.stub!(:gets).and_return("Y")

        path = File.join(Thor::Util.thor_root, Digest::MD5.hexdigest(@location + "random"))
        File.should_receive(:open).with(path, "w")
      end

      it "updates existing thor files" do
        path = File.join(Thor::Util.thor_root, @original_yaml["random"][:filename])
        if File.directory? path
          FileUtils.should_receive(:rm_rf).with(path)
        else
          File.should_receive(:delete).with(path)
        end
        silence(:stdout) { Thor::Runner.start(["update", "random"]) }
      end

      it "installs thor files" do
        ARGV.replace ["install", @location]
        silence(:stdout) { Thor::Runner.start }
      end
    end
  end
end
