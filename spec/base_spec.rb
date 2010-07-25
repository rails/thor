require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'thor/base'

class Amazing
  desc "hello", "say hello"
  def hello
    puts "Hello"
  end
end

describe Thor::Base do
  describe "#initialize" do
    it "sets arguments array" do
      base = MyCounter.new [1, 2]
      base.first.must == 1
      base.second.must == 2
    end

    it "sets arguments default values" do
      base = MyCounter.new [1]
      base.second.must == 2
    end

    it "sets options default values" do
      base = MyCounter.new [1, 2]
      base.options[:third].must == 3
    end

    it "allows options to be given as symbols or strings" do
      base = MyCounter.new [1, 2], :third => 4
      base.options[:third].must == 4

      base = MyCounter.new [1, 2], "third" => 4
      base.options[:third].must == 4
    end

    it "creates options with indifferent access" do
      base = MyCounter.new [1, 2], :third => 3
      base.options['third'].must == 3
    end

    it "creates options with magic predicates" do
      base = MyCounter.new [1, 2], :third => 3
      base.options.third.must == 3
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
      Scripts::MyScript.start(["zoo", "my_special_param", "--param=normal_param"]).must == "my_special_param"
    end

    it "does not set a value in the options hash" do
      BrokenCounter.start(["1", "2", "--third", "3"])[0].must be_nil
    end
  end

  describe "#arguments" do
    it "returns the arguments for the class" do
      MyCounter.arguments.must have(2).items
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
      options = Scripts::MyScript.class_options
      options[:force].must_not be_required
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
      @content = capture(:stdout) { MyCounter.help(Thor::Base.shell.new) }
    end

    it "shows options description" do
      @content.must =~ /# The third argument/
    end

    it "shows usage with banner content" do
      @content.must =~ /\[\-\-third=THREE\]/
    end

    it "shows default values below description" do
      @content.must =~ /# Default: 3/
    end

    it "shows options in different groups" do
      @content.must =~ /Options\:/
      @content.must =~ /Runtime options\:/
      @content.must =~ /\-p, \[\-\-pretend\]/
    end

    it "use padding in options that does not have aliases" do
      @content.must =~ /^  -t, \[--third/
      @content.must =~ /^      \[--fourth/
    end

    it "allows extra options to be given" do
      hash = { "Foo" => B.class_options.values }

      content = capture(:stdout) { MyCounter.send(:class_options_help, Thor::Base.shell.new, hash) }
      content.must =~ /Foo options\:/
      content.must =~ /--last-name=LAST_NAME/
    end
  end

  describe "#namespace" do
    it "returns the default class namespace" do
      Scripts::MyScript.namespace.must == "scripts:my_script"
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
      Thor::Base.subclasses.must include(Scripts::MyScript)
    end
  end

  describe "#subclass_files" do
    it "returns tracked subclasses, grouped by the files they come from" do
      thorfile = File.join(File.dirname(__FILE__), "fixtures", "script.thor")
      Thor::Base.subclass_files[File.expand_path(thorfile)].must == [
        MyScript, MyScript::AnotherScript, MyChildScript, Barn,
        Scripts::MyScript, Scripts::MyDefaults, Scripts::ChildDefault
      ]
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
        klass = Class.new(Thor::Group)
        klass.class_eval "def shell; end"
      }.must raise_error(RuntimeError, /"shell" is a Thor reserved word and cannot be defined as task/)
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

  describe "#from_superclass" do
    it "does not send a method to the superclass if the superclass does not respond to it" do
      MyCounter.get_from_super.must == 13
    end
  end

  describe "#start" do
    it "raises an error instead of rescueing if --debug is given" do
      lambda {
        MyScript.start ["what", "--debug"]
      }.must raise_error(Thor::UndefinedTaskError, 'Could not find task "what" in "my_script" namespace.')
    end

    it "does not steal args" do
      args = ["foo", "bar", "--force", "true"]
      MyScript.start(args)
      args.must == ["foo", "bar", "--force", "true"]
    end

    it "checks unknown options" do
      capture(:stderr) {
        MyScript.start(["foo", "bar", "--force", "true", "--unknown", "baz"])
      }.strip.must == "Unknown switches '--unknown'"
    end

    it "checks unknown options except specified" do
      capture(:stderr) {
        MyScript.start(["with_optional", "NAME", "--omg", "--invalid"]).must == ["NAME", {}]
      }.strip.must be_empty
    end
  end

  describe "attr_*" do
    it "should not add attr_reader as a task" do
      capture(:stderr){ MyScript.start(["another_attribute"]) }.must =~ /Could not find/
    end

    it "should not add attr_writer as a task" do
      capture(:stderr){ MyScript.start(["another_attribute=", "foo"]) }.must =~ /Could not find/
    end

    it "should not add attr_accessor as a task" do
      capture(:stderr){ MyScript.start(["some_attribute"]) }.must =~ /Could not find/
      capture(:stderr){ MyScript.start(["some_attribute=", "foo"]) }.must =~ /Could not find/
    end
  end
end
