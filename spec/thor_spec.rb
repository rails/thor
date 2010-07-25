require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Thor do
  describe "#method_option" do
    it "sets options to the next method to be invoked" do
      args = ["foo", "bar", "--force"]
      arg, options = MyScript.start(args)
      options.must == { "force" => true }
    end

    describe ":lazy_default" do
      it "is absent when option is not specified" do
        arg, options = MyScript.start(["with_optional"])
        options.must == {}
      end

      it "sets a default that can be overridden for strings" do
        arg, options = MyScript.start(["with_optional", "--lazy"])
        options.must == { "lazy" => "yes" }

        arg, options = MyScript.start(["with_optional", "--lazy", "yesyes!"])
        options.must == { "lazy" => "yesyes!" }
      end

      it "sets a default that can be overridden for numerics" do
        arg, options = MyScript.start(["with_optional", "--lazy-numeric"])
        options.must == { "lazy_numeric" => 42 }

        arg, options = MyScript.start(["with_optional", "--lazy-numeric", 20000])
        options.must == { "lazy_numeric" => 20000 }
      end

      it "sets a default that can be overridden for arrays" do
        arg, options = MyScript.start(["with_optional", "--lazy-array"])
        options.must == { "lazy_array" => %w[eat at joes] }

        arg, options = MyScript.start(["with_optional", "--lazy-array", "hello", "there"])
        options.must == { "lazy_array" => %w[hello there] }
      end

      it "sets a default that can be overridden for hashes" do
        arg, options = MyScript.start(["with_optional", "--lazy-hash"])
        options.must == { "lazy_hash" => {'swedish' => 'meatballs'} }

        arg, options = MyScript.start(["with_optional", "--lazy-hash", "polish:sausage"])
        options.must == { "lazy_hash" => {'polish' => 'sausage'} }
      end
    end

    describe "when :for is supplied" do
      it "updates an already defined task" do
        args, options = MyChildScript.start(["animal", "horse", "--other=fish"])
        options[:other].must == "fish"
      end

      describe "and the target is on the parent class" do
        it "updates an already defined task" do
          args = ["example_default_task", "my_param", "--new-option=verified"]
          options = Scripts::MyScript.start(args)
          options[:new_option].must == "verified"
        end

        it "adds a task to the tasks list if the updated task is on the parent class" do
          Scripts::MyScript.tasks["example_default_task"].must_not be_nil
        end

        it "clones the parent task" do
          Scripts::MyScript.tasks["example_default_task"].must_not == MyChildScript.tasks["example_default_task"]
        end
      end
    end
  end

  describe "#default_task" do
    it "sets a default task" do
      MyScript.default_task.must == "example_default_task"
    end

    it "invokes the default task if no command is specified" do
      MyScript.start([]).must == "default task"
    end

    it "invokes the default task if no command is specified even if switches are given" do
      MyScript.start(["--with", "option"]).must == {"with"=>"option"}
    end

    it "inherits the default task from parent" do
      MyChildScript.default_task.must == "example_default_task"
    end
  end

  describe "#map" do
    it "calls the alias of a method if one is provided" do
      MyScript.start(["-T", "fish"]).must == ["fish"]
    end

    it "calls the alias of a method if several are provided via .map" do
      MyScript.start(["-f", "fish"]).must == ["fish", {}]
      MyScript.start(["--foo", "fish"]).must == ["fish", {}]
    end

    it "inherits all mappings from parent" do
      MyChildScript.default_task.must == "example_default_task"
    end
  end

  describe "#desc" do
    it "provides description for a task" do
      content = capture(:stdout) { MyScript.start(["help"]) }
      content.must =~ /thor my_script:zoo\s+# zoo around/m
    end

    it "provides no namespace if $thor_runner is false" do
      begin
        $thor_runner = false
        content = capture(:stdout) { MyScript.start(["help"]) }
        content.must =~ /thor zoo\s+# zoo around/m
      ensure
        $thor_runner = true
      end
    end

    describe "when :for is supplied" do
      it "overwrites a previous defined task" do
        capture(:stdout) { MyChildScript.start(["help"]) }.must =~ /animal KIND \s+# fish around/m
      end
    end

    describe "when :hide is supplied" do
      it "does not show the task in help" do
        capture(:stdout) { MyScript.start(["help"]) }.must_not =~ /this is hidden/m
      end

      it "but the task is still invokcable not show the task in help" do
        MyScript.start(["hidden", "yesyes"]).must == ["yesyes"]
      end
    end
  end

  describe "#method_options" do
    it "sets default options if called before an initializer" do
      options = MyChildScript.class_options
      options[:force].type.must == :boolean
      options[:param].type.must == :numeric
    end

    it "overwrites default options if called on the method scope" do
      args = ["zoo", "--force", "--param", "feathers"]
      options = MyChildScript.start(args)
      options.must == { "force" => true, "param" => "feathers" }
    end

    it "allows default options to be merged with method options" do
      args = ["animal", "bird", "--force", "--param", "1.0", "--other", "tweets"]
      arg, options = MyChildScript.start(args)
      arg.must == 'bird'
      options.must == { "force"=>true, "param"=>1.0, "other"=>"tweets" }
    end
  end

  describe "#start" do
    it "calls a no-param method when no params are passed" do
      MyScript.start(["zoo"]).must == true
    end

    it "calls a single-param method when a single param is passed" do
      MyScript.start(["animal", "fish"]).must == ["fish"]
    end

    it "does not set options in attributes" do
      MyScript.start(["with_optional", "--all"]).must == [nil, { "all" => true }]
    end

    it "raises an error if a required param is not provided" do
      capture(:stderr) { MyScript.start(["animal"]) }.strip.must == '"animal" was called incorrectly. Call as "thor my_script:animal TYPE".'
    end

    it "raises an error if the invoked task does not exist" do
      capture(:stderr) { Amazing.start(["animal"]) }.strip.must == 'Could not find task "animal" in "amazing" namespace.'
    end

    it "calls method_missing if an unknown method is passed in" do
      MyScript.start(["unk", "hello"]).must == [:unk, ["hello"]]
    end

    it "does not call a private method no matter what" do
      capture(:stderr) { MyScript.start(["what"]) }.strip.must == 'Could not find task "what" in "my_script" namespace.'
    end

    it "uses task default options" do
      options = MyChildScript.start(["animal", "fish"]).last
      options.must == { "other" => "method default" }
    end

    it "raises when an exception happens within the task call" do
      lambda { MyScript.start(["call_myself_with_wrong_arity"]) }.must raise_error(ArgumentError)
    end
  end

  describe "#subcommand" do
    it "maps a given subcommand to another Thor subclass" do
      barn_help = capture(:stdout){ Scripts::MyDefaults.start(["barn"]) }
      barn_help.must include("barn help [COMMAND]  # Describe subcommands or one specific subcommand")
    end

    it "passes commands to subcommand classes" do
      capture(:stdout){ Scripts::MyDefaults.start(["barn", "open"]) }.strip.must == "Open sesame!"
    end

    it "passes arguments to subcommand classes" do
      capture(:stdout){ Scripts::MyDefaults.start(["barn", "open", "shotgun"]) }.strip.must == "That's going to leave a mark."
    end

    it "ignores unknown options (the subcommand class will handle them)" do
      capture(:stdout){ Scripts::MyDefaults.start(["barn", "paint", "blue", "--coats", "4"])}.strip.must == "4 coats of blue paint"
    end
  end

  describe "#help" do
    def shell
      @shell ||= Thor::Base.shell.new
    end

    describe "on general" do
      before(:each) do
        @content = capture(:stdout){ MyScript.help(shell) }
      end

      it "provides useful help info for the help method itself" do
        @content.must =~ /help \[TASK\]\s+# Describe available tasks/
      end

      it "provides useful help info for a method with params" do
        @content.must =~ /animal TYPE\s+# horse around/
      end

      it "uses the maximum terminal size to show tasks" do
        @shell.should_receive(:terminal_width).and_return(80)
        content = capture(:stdout){ MyScript.help(shell) }
        content.must =~ /aaa\.\.\.$/
      end

      it "provides description for tasks from classes in the same namespace" do
        @content.must =~ /baz\s+# do some bazing/
      end

      it "shows superclass tasks" do
        content = capture(:stdout){ MyChildScript.help(shell) }
        content.must =~ /foo BAR \s+# do some fooing/
      end

      it "shows class options information" do
        content = capture(:stdout){ MyChildScript.help(shell) }
        content.must =~ /Options\:/
        content.must =~ /\[\-\-param=N\]/
      end

      it "injects class arguments into default usage" do
        content = capture(:stdout){ Scripts::MyScript.help(shell) }
        content.must =~ /zoo ACCESSOR \-\-param\=PARAM/
      end
    end

    describe "for a specific task" do
      it "provides full help info when talking about a specific task" do
        capture(:stdout) { MyScript.task_help(shell, "foo") }.must == <<-END
Usage:
  thor my_script:foo BAR

Options:
  [--force]  # Force to do some fooing

do some fooing
  This is more info!
  Everyone likes more info!
END
      end

      it "raises an error if the task can't be found" do
        lambda {
          MyScript.task_help(shell, "unknown")
        }.must raise_error(Thor::UndefinedTaskError, 'Could not find task "unknown" in "my_script" namespace.')
      end

      it "normalizes names before claiming they don't exist" do
        capture(:stdout) { MyScript.task_help(shell, "name-with-dashes") }.must =~ /thor my_script:name-with-dashes/
      end

      it "uses the long description if it exists" do
        capture(:stdout) { MyScript.task_help(shell, "long_description") }.must == <<-HELP
Usage:
  thor my_script:long_description

Description:
  This is a really really really long description. Here you go. So very long.

  It even has two paragraphs.
HELP
      end

      it "doesn't assign the long description to the next task without one" do
        capture(:stdout) do
          MyScript.task_help(shell, "name_with_dashes")
        end.must_not =~ /so very long/i
      end
    end

    describe "instance method" do
      it "calls the class method" do
        capture(:stdout){ MyScript.start(["help"]) }.must =~ /Tasks:/
      end

      it "calls the class method" do
        capture(:stdout){ MyScript.start(["help", "foo"]) }.must =~ /Usage:/
      end
    end
  end

  describe "when creating tasks" do
    it "prints a warning if a public method is created without description or usage" do
      capture(:stdout) {
        klass = Class.new(Thor)
        klass.class_eval "def hello_from_thor; end"
      }.must =~ /\[WARNING\] Attempted to create task "hello_from_thor" without usage or description/
    end

    it "does not print if overwriting a previous task" do
      capture(:stdout) {
        klass = Class.new(Thor)
        klass.class_eval "def help; end"
      }.must be_empty
    end
  end
end
