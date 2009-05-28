require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'thor/options'

class Amazing
  desc "hello", "say hello"
  def hello
    puts "Hello"
  end
end

describe Thor::Base do
  describe "#no_tasks" do
    it "avoids methods being added as tasks" do
      MyScript.tasks.keys.must include("animal")
      MyScript.tasks.keys.must_not include("this_is_not_a_task")
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

  describe "#default_options" do
    it "sets default options overwriting superclass definitions" do
      options = Scripts::MyGrandChildScript.default_options
      options[:force].must be_optional
      options[:param].must be_required
    end
  end

  describe "#subclasses" do
    it "tracks its subclasses in an Array" do
      Thor.subclasses.must include(MyScript)
      Thor.subclasses.must include(MyChildScript)
      Thor.subclasses.must include(Scripts::MyGrandChildScript)

      MyChildScript.subclasses.must include(Scripts::MyGrandChildScript)
      MyChildScript.subclasses.must_not include(MyScript)
    end
  end

  describe "#subclass_files" do
    it "returns tracked subclasses, grouped by the files they come from" do
      thorfile = File.join(File.dirname(__FILE__), "fixtures", "script.thor")
      Thor.subclass_files[File.expand_path(thorfile)].must == [ MyScript, MyChildScript, Scripts::MyGrandChildScript ]
    end

    it "tracks a single subclass across multiple files" do
      thorfile = File.join(File.dirname(__FILE__), "fixtures", "task.thor")
      Thor.subclass_files[File.expand_path(thorfile)].must include(Amazing)
      Thor.subclass_files[File.expand_path(__FILE__)].must include(Amazing)
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

  describe "#maxima" do
    it "returns the maximum length for usage, description and options" do
      MyScript.maxima.description.must == 64
      MyScript.maxima.usage.must       == 28
      MyScript.maxima.options.must     == 19
    end
  end
end
