require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'thor/options'

class Amazing
  desc "hello", "say hello"
  def hello
    puts "Hello"
  end
end

describe Thor::Base do
  describe "#argument" do
    it "sets options to the next method to be invoked" do
      args = ["bar", "bla", "bla", "--option1", "cool"]
      arg1, arg2, options = MyScript.start(args)
      options.must == { "option1" => "cool" }
    end

    it "ignores default option" do
      lambda {
        MyScript.start(["bar", "bla", "bla"])
      }.must raise_error(Thor::Options::Error, "no value provided for required argument '--option1'")
    end
  end

  describe "#option" do
    it "sets options to the next method to be invoked" do
      args = ["foo", "bar", "--force"]
      arg, options = MyScript.start(args)
      options.must == { "force" => true }
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
