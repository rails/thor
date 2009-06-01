require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Thor do
  describe "#method_option" do
    it "sets options to the next method to be invoked" do
      args = ["foo", "bar", "--force"]
      arg, options = MyScript.start(args)
      options.must == { "force" => true }
    end

    describe "when :for is supplied" do
      it "updates an already defined task" do
        args, options = MyChildScript.start(["animal", "horse", "--other=fish"])
        options[:other].must == "fish"
      end

      describe "and the target is on the parent class" do
        it "updates an already defined task" do
          args = ["example_default_task", "my_param", "--new_option=verified"]
          options = Scripts::MyGrandChildScript.start(args)
          options[:new_option].must == "verified"
        end

        it "adds a task to the tasks list if the updated task is on the parent class" do
          Scripts::MyGrandChildScript.tasks["example_default_task"].must_not be_nil
        end

        it "clones the parent task" do
          Scripts::MyGrandChildScript.tasks["example_default_task"].must_not == MyChildScript.tasks["example_default_task"]
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
    before(:all) do
      @content = capture(:stdout) { MyScript.start(["help"]) }
    end

    it "provides description for a task" do
      @content.must =~ /zoo +# zoo around/
    end

    describe "when :for is supplied" do
      it "overwrites a previous defined task" do
        capture(:stdout) { MyChildScript.start(["help"]) }.must =~ /animal KIND \[\-\-other=OTHER\] +# fish around/
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

    it "raises an error if a required param is not provided" do
      capture(:stderr) { MyScript.start(["animal"]) }.must =~ /'animal' was called incorrectly\. Call as 'my_script:animal TYPE'/
    end

    it "raises an error if the invoked task does not exist" do
      capture(:stderr) { Amazing.start(["animal"]) }.must =~ /The amazing namespace doesn't have a 'animal' task/
    end

    it "calls method_missing if an unknown method is passed in" do
      MyScript.start(["unk", "hello"]).must == [:unk, ["hello"]]
    end

    it "does not call a private method no matter what" do
      lambda { MyScript.start(["what"]) }.must raise_error(NoMethodError, "the 'what' task of MyScript is private")
    end

    it "raises when an exception happens within the task call" do
      lambda { MyScript.start(["call_myself_with_wrong_arity"]) }.must raise_error
    end
  end

  describe "#invoke" do
    it "invokes the named command regardless of the command line options with invoke()" do
      MyScript.invoke(:animal, ["fish"]).must == ["fish"]
    end
  end

  describe "#help" do
    describe "on general" do
      before(:each) do
        @content = capture(:stdout){ MyScript.help }
      end

      it "provides useful help info for the help method itself" do
        @content.must =~ /help \[TASK\] +# Describe available tasks/
      end

      it "provides useful help info for a method with params" do
        @content.must =~ /animal TYPE +# horse around/
      end

      it "provides useful help info for a method with options" do
        @content.must =~ /foo BAR \[\-\-force\] +# do some fooing/
      end

      it "shows superclass tasks" do
        capture(:stdout){ MyChildScript.help }.must =~ /foo BAR \[\-\-force\] +# do some fooing/
      end

      it "shows global options information" do
        capture(:stdout){ MyChildScript.help }.must =~ /\[\-\-param=N\]/
      end
    end

    describe "for a specific task" do
      it "provides full help info when talking about a specific task" do
        capture(:stdout) { MyScript.help("foo") }.must == <<END
Usage:
  foo BAR [--force]

do some fooing
  This is more info!
  Everyone likes more info!
END
      end

      it "raises an error if the task can't be found" do
        lambda {
          MyScript.help("unknown")
        }.must raise_error(Thor::Error, "task 'unknown' could not be found in namespace 'my_script'")
      end
    end

    describe "options" do
      it "shows the namespace if required" do
        capture(:stdout){ MyScript.help(:namespace => true) }.must =~ /my_script:foo BAR/
      end

      it "does not show superclass tasks if required" do
        capture(:stdout){ MyScript.help(:skip_inherited => true) }.must_not =~ /help/
      end
    end

    describe "instance method" do
      it "calls the class method" do
        stub(MyScript).help(nil, :namespace => nil)
        MyScript.start(["help"])
      end
    end
  end
end
