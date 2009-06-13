require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'thor/options'

class Amazing
  desc "hello", "say hello"
  def hello
    puts "Hello"
  end
end

describe Thor::Base do
  describe "#initialize" do
    it "sets values in arguments" do
      base = MyCounter.new [1, 2]
      base.first.must == 1
      base.second.must == 2
    end

    it "sets options hash" do
      base = MyCounter.new [1, 2], :third => 3
      base.options[:third].must == 3
    end

    it "sets options with indifferent access" do
      base = MyCounter.new [1, 2], :third => 3
      base.options['third'].must == 3
    end

    it "sets options with magic predicates" do
      base = MyCounter.new [1, 2], :third => 3
      base.options.third.must == 3
    end

    it "sets shell value" do
      shell = Thor::Shell::Basic.new
      base = MyCounter.new [1, 2], { }, :shell => shell
      base.shell.must == shell
    end

    it "sets the base value on the shell if an accessor is available" do
      shell = Thor::Shell::Basic.new
      shell.instance_eval "def base=(base); @base = base; end; def base; @base; end"
      base = MyCounter.new [1, 2], { }, :shell => shell
      shell.base.must == base
    end
  end

  describe "#invoke" do
    it "invokes an specific task" do
      MyScript.new.invoke(:animal, "fish").must == ["fish"]
    end
  end

  describe "#shell" do
    it "returns the shell in use" do
      MyCounter.new.shell.class.must == Thor::Shell::Basic
    end
  end

  describe "#root=" do
    it "gets the current directory and expands the path to set the root" do
      base = MyCounter.new
      base.root = "here"
      base.root.must == File.expand_path(File.join(File.dirname(__FILE__), "..", "here"))
    end

    it "does not use the current directory if one is given" do
      base = MyCounter.new
      base.root = "/"
      base.root.must == "/"
    end

    it "uses the current directory if none is given" do
      MyCounter.new.root.must == File.expand_path(File.join(File.dirname(__FILE__), ".."))
    end
  end

  describe "#no_tasks" do
    it "avoids methods being added as tasks" do
      MyScript.tasks.keys.must include("animal")
      MyScript.tasks.keys.must_not include("this_is_not_a_task")
    end
  end

  describe "#argument" do
    it "sets a value as required and creates an accessor for it" do
      MyCounter.start(["1", "2", "--third", "3"])[0].must == 1
      Scripts::MyGrandChildScript.start(["zoo", "my_special_param", "--param=normal_param"]).must == "my_special_param"
    end

    it "does not set a value in the options hash" do
      BrokenCounter.start(["1", "2", "--third", "3"])[0].must be_nil
    end
  end

  describe "#arguments" do
    it "returns the arguments for the class" do
      MyCounter.arguments.must have(2).items
      MyCounter.arguments[0].must be_argument
      MyCounter.arguments[1].must be_argument
    end
  end

  describe "#class_option" do
    it "sets options class wise" do
      MyCounter.start(["1", "2", "--third", "3"])[2].must == 3
    end

    it "does not create an acessor for it" do
      BrokenCounter.start(["1", "2", "--third", "3"])[3].must be_false
    end
  end

  describe "#class_options" do
    it "sets default options overwriting superclass definitions" do
      options = Scripts::MyGrandChildScript.class_options
      options[:force].must be_optional
    end
  end

  describe "#namespace" do
    it "returns the default class namespace" do
      Scripts::MyGrandChildScript.namespace.must == "scripts:my_grand_child_script"
    end

    it "sets a namespace to the class" do
      Scripts::MyDefaults.namespace.must == "default"
    end
  end

  describe "#group" do
    it "sets a group name" do
      MyScript.group_name.must == "script"
    end

    it "inherits the group name from parent" do
      MyChildScript.group_name.must == "script"
    end

    it "defaults to standard if no group name is given" do
      Amazing.group_name.must == "standard"
    end
  end

  describe "#subclasses" do
    it "tracks its subclasses in an Array" do
      Thor::Base.subclasses.must include(MyScript)
      Thor::Base.subclasses.must include(MyChildScript)
      Thor::Base.subclasses.must include(Scripts::MyGrandChildScript)
    end
  end

  describe "#subclass_files" do
    it "returns tracked subclasses, grouped by the files they come from" do
      thorfile = File.join(File.dirname(__FILE__), "fixtures", "script.thor")
      Thor::Base.subclass_files[File.expand_path(thorfile)].must == [ MyScript, MyChildScript, Scripts::MyGrandChildScript, Scripts::MyDefaults ]
    end

    it "tracks a single subclass across multiple files" do
      thorfile = File.join(File.dirname(__FILE__), "fixtures", "task.thor")
      Thor::Base.subclass_files[File.expand_path(thorfile)].must include(Amazing)
      Thor::Base.subclass_files[File.expand_path(__FILE__)].must include(Amazing)
    end
  end

  describe "#tasks" do
    it "returns a list with all tasks defined in this class" do
      MyChildScript.new.must respond_to("animal")
      MyChildScript.tasks.keys.must include("animal")
    end
  end

  describe "#all_tasks" do
    it "returns a list with all tasks defined in this class plus superclasses" do
      MyChildScript.new.must respond_to("foo")
      MyChildScript.all_tasks.keys.must include("foo")
    end
  end

  describe "#remove_task" do
    it "removes the task from its tasks hash" do
      MyChildScript.tasks.keys.must_not include("bar")
      MyChildScript.tasks.keys.must_not include("boom")
    end

    it "undefines the method if desired" do
      MyChildScript.new.must_not respond_to("boom")
    end
  end

  describe "#[]" do
    it "retrieves an specific task object" do
      MyScript[:foo].class.must == Thor::Task
      MyChildScript[:foo].class.must == Thor::Task
      Scripts::MyGrandChildScript[:foo].class.must == Thor::Task
    end

    it "returns a dynamic task to allow method missing invocation" do
      MyScript[:none].class.must == Thor::Task
      MyScript[:none].description =~ /dynamic/
    end
  end
end
