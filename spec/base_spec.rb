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
    it "invokes a task inside another task" do
      capture(:stdout){ A.new.invoke(:two) }.must == "2\n3\n"
    end

    it "invokes a task just once" do
      capture(:stdout){ A.new.invoke(:one) }.must == "1\n2\n3\n"
    end

    it "invokes a task just once even if they belongs to different classes" do
      capture(:stdout){ D.new.invoke(:one) }.must == "1\n2\n3\n4\n5\n"
    end

    it "invokes a task with arguments" do
      A.new.invoke(:five, [5]).must be_true
      A.new.invoke(:five, [7]).must be_false
    end

    it "invokes the default task if none is given to a Thor class" do
      content = capture(:stdout){ A.new.invoke("b") }
      content.must =~ /Tasks/
      content.must =~ /LAST_NAME/
    end

    it "accepts a class as argument" do
      content = capture(:stdout){ A.new.invoke(B) }
      content.must =~ /Tasks/
      content.must =~ /LAST_NAME/
    end

    xit "accepts a Thor instance as argument" do
      capture(:stdout){ A.new.invoke("b:one", ["Valim", "José"]) }.must == "Valim, José\n"
    end

    xit "reparses options in the new class" do
    end

    it "shares initialize options with invoked class" do
      A.new([], :foo => :bar).invoke("b:two").must == { "foo" => :bar }
    end

    it "dump configuration values to be used in the invoked class" do
      base = A.new
      base.invoke("b:three").shell.must == base.shell
    end

    it "invokes a Thor::Group and all of its tasks" do
      capture(:stdout){ A.new.invoke(:c) }.must == "1\n2\n3\n"
    end

    it "does not invoke a Thor::Group twice" do
      base = A.new
      silence(:stdout){ base.invoke(:c) }
      capture(:stdout){ base.invoke(:c) }.must be_empty
    end

    it "does not invoke any of Thor::Group tasks twice" do
      base = A.new
      silence(:stdout){ base.invoke(:c) }
      capture(:stdout){ base.invoke("c:one") }.must be_empty
    end

    it "raises Thor::UndefinedTaskError if the task can't be found" do
      lambda do
        A.new.invoke("foo:bar")
      end.must raise_error(Thor::UndefinedTaskError)
    end

    it "raises an error if a non Thor class is given" do
      lambda do
        A.new.invoke(Object)
      end.must raise_error(RuntimeError, "Expected Thor class, got Object")
    end
  end

  describe "#shell" do
    it "returns the shell in use" do
      MyCounter.new.shell.class.must == Thor::Shell::Basic
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

  describe "#remove_argument" do
    it "removes previous defined arguments from class" do
      ClearCounter.arguments.must be_empty
    end

    it "undefine accessors if required" do
      ClearCounter.new.must_not respond_to(:first)
      ClearCounter.new.must_not respond_to(:second)
    end
  end

  describe "#remove_class_option" do
    it "removes previous defined class option" do
      ClearCounter.class_options[:third].must be_nil
    end
  end

  describe "#class_options_help" do
    before(:each) do
      @content = capture(:stdout) { MyCounter.help(Thor::Shell::Basic.new) }
    end

    it "shows options description" do
      @content.must =~ /# The third argument\./
    end

    it "does not show usage with default values inside" do
      @content.must =~ /\[\-\-third=N\]/
    end

    it "shows default values below description" do
      @content.must =~ /# Default: 3/
    end

    it "shows options in different groups" do
      @content.must =~ /Options\:/
      @content.must =~ /Runtime options\:/
      @content.must =~ /\-p, \[\-\-pretend\]/
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
    it "sets a group" do
      MyScript.group.must == "script"
    end

    it "inherits the group from parent" do
      MyChildScript.group.must == "script"
    end

    it "defaults to standard if no group is given" do
      Amazing.group.must == "standard"
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

    it "raises an error if a task with reserved word is defined" do
      lambda {
        MyCounter.class_eval "def all; end"
      }.must raise_error(ScriptError, /'all' is a Thor reserved word and cannot be defined as task/)
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
end
