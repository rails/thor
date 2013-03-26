require 'helper'
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
      expect(base.first).to eq(1)
      expect(base.second).to eq(2)
    end

    it "sets arguments default values" do
      base = MyCounter.new [1]
      expect(base.second).to eq(2)
    end

    it "sets options default values" do
      base = MyCounter.new [1, 2]
      expect(base.options[:third]).to eq(3)
    end

    it "allows options to be given as symbols or strings" do
      base = MyCounter.new [1, 2], :third => 4
      expect(base.options[:third]).to eq(4)

      base = MyCounter.new [1, 2], "third" => 4
      expect(base.options[:third]).to eq(4)
    end

    it "creates options with indifferent access" do
      base = MyCounter.new [1, 2], :third => 3
      expect(base.options['third']).to eq(3)
    end

    it "creates options with magic predicates" do
      base = MyCounter.new [1, 2], :third => 3
      expect(base.options.third).to eq(3)
    end
  end

  describe "#no_commands" do
    it "avoids methods being added as commands" do
      expect(MyScript.commands.keys).to include("animal")
      expect(MyScript.commands.keys).not_to include("this_is_not_a_command")
    end
  end

  describe "#argument" do
    it "sets a value as required and creates an accessor for it" do
      expect(MyCounter.start(["1", "2", "--third", "3"])[0]).to eq(1)
      expect(Scripts::MyScript.start(["zoo", "my_special_param", "--param=normal_param"])).to eq("my_special_param")
    end

    it "does not set a value in the options hash" do
      expect(BrokenCounter.start(["1", "2", "--third", "3"])[0]).to be_nil
    end
  end

  describe "#arguments" do
    it "returns the arguments for the class" do
      expect(MyCounter.arguments).to have(2).items
    end
  end

  describe ":aliases" do
    it "supports string aliases without a dash prefix" do
      expect(MyCounter.start(["1", "2", "-z", "3"])[4]).to eq(3)
    end

    it "supports symbol aliases" do
      expect(MyCounter.start(["1", "2", "-y", "3"])[5]).to eq(3)
      expect(MyCounter.start(["1", "2", "-r", "3"])[5]).to eq(3)
    end
  end

  describe "#class_option" do
    it "sets options class wise" do
      expect(MyCounter.start(["1", "2", "--third", "3"])[2]).to eq(3)
    end

    it "does not create an accessor for it" do
      expect(BrokenCounter.start(["1", "2", "--third", "3"])[3]).to be_false
    end
  end

  describe "#class_options" do
    it "sets default options overwriting superclass definitions" do
      options = Scripts::MyScript.class_options
      expect(options[:force]).not_to be_required
    end
  end

  describe "#remove_argument" do
    it "removes previous defined arguments from class" do
      expect(ClearCounter.arguments).to be_empty
    end

    it "undefine accessors if required" do
      expect(ClearCounter.new).not_to respond_to(:first)
      expect(ClearCounter.new).not_to respond_to(:second)
    end
  end

  describe "#remove_class_option" do
    it "removes previous defined class option" do
      expect(ClearCounter.class_options[:third]).to be_nil
    end
  end

  describe "#class_options_help" do
    before do
      @content = capture(:stdout) { MyCounter.help(Thor::Base.shell.new) }
    end

    it "shows options description" do
      expect(@content).to match(/# The third argument/)
    end

    it "shows usage with banner content" do
      expect(@content).to match(/\[\-\-third=THREE\]/)
    end

    it "shows default values below description" do
      expect(@content).to match(/# Default: 3/)
    end

    it "shows options in different groups" do
      expect(@content).to match(/Options\:/)
      expect(@content).to match(/Runtime options\:/)
      expect(@content).to match(/\-p, \[\-\-pretend\]/)
    end

    it "use padding in options that does not have aliases" do
      expect(@content).to match(/^  -t, \[--third/)
      expect(@content).to match(/^          \[--fourth/)
    end

    it "allows extra options to be given" do
      hash = { "Foo" => B.class_options.values }

      content = capture(:stdout) { MyCounter.send(:class_options_help, Thor::Base.shell.new, hash) }
      expect(content).to match(/Foo options\:/)
      expect(content).to match(/--last-name=LAST_NAME/)
    end

    it "displays choices for enums" do
      content = capture(:stdout) { Enum.help(Thor::Base.shell.new) }
      expect(content).to match(/Possible values\: apple, banana/)
    end
  end

  describe "#namespace" do
    it "returns the default class namespace" do
      expect(Scripts::MyScript.namespace).to eq("scripts:my_script")
    end

    it "sets a namespace to the class" do
      expect(Scripts::MyDefaults.namespace).to eq("default")
    end
  end

  describe "#group" do
    it "sets a group" do
      expect(MyScript.group).to eq("script")
    end

    it "inherits the group from parent" do
      expect(MyChildScript.group).to eq("script")
    end

    it "defaults to standard if no group is given" do
      expect(Amazing.group).to eq("standard")
    end
  end

  describe "#subclasses" do
    it "tracks its subclasses in an Array" do
      expect(Thor::Base.subclasses).to include(MyScript)
      expect(Thor::Base.subclasses).to include(MyChildScript)
      expect(Thor::Base.subclasses).to include(Scripts::MyScript)
    end
  end

  describe "#subclass_files" do
    it "returns tracked subclasses, grouped by the files they come from" do
      thorfile = File.join(File.dirname(__FILE__), "fixtures", "script.thor")
      expect(Thor::Base.subclass_files[File.expand_path(thorfile)]).to eq([
        MyScript, MyScript::AnotherScript, MyChildScript, Barn,
        PackageNameScript, Scripts::MyScript, Scripts::MyDefaults,
        Scripts::ChildDefault, Scripts::Arities
      ])
    end

    it "tracks a single subclass across multiple files" do
      thorfile = File.join(File.dirname(__FILE__), "fixtures", "command.thor")
      expect(Thor::Base.subclass_files[File.expand_path(thorfile)]).to include(Amazing)
      expect(Thor::Base.subclass_files[File.expand_path(__FILE__)]).to include(Amazing)
    end
  end

  describe "#commands" do
    it "returns a list with all commands defined in this class" do
      expect(MyChildScript.new).to respond_to("animal")
      expect(MyChildScript.commands.keys).to include("animal")
    end

    it "raises an error if a command with reserved word is defined" do
      expect {
        klass = Class.new(Thor::Group)
        klass.class_eval "def shell; end"
      }.to raise_error(RuntimeError, /"shell" is a Thor reserved word and cannot be defined as command/)
    end
  end

  describe "#all_commands" do
    it "returns a list with all commands defined in this class plus superclasses" do
      expect(MyChildScript.new).to respond_to("foo")
      expect(MyChildScript.all_commands.keys).to include("foo")
    end
  end

  describe "#remove_command" do
    it "removes the command from its commands hash" do
      expect(MyChildScript.commands.keys).not_to include("bar")
      expect(MyChildScript.commands.keys).not_to include("boom")
    end

    it "undefines the method if desired" do
      expect(MyChildScript.new).not_to respond_to("boom")
    end
  end

  describe "#from_superclass" do
    it "does not send a method to the superclass if the superclass does not respond to it" do
      expect(MyCounter.get_from_super).to eq(13)
    end
  end

  describe "#start" do
    it "raises an error instead of rescueing if THOR_DEBUG=1 is given" do
      begin
        ENV["THOR_DEBUG"] = 1
        expect {
          MyScript.start ["what", "--debug"]
        }.to raise_error(Thor::UndefinedcommandError, 'Could not find command "what" in "my_script" namespace.')
      rescue
        ENV["THOR_DEBUG"] = nil
      end
    end

    it "does not steal args" do
      args = ["foo", "bar", "--force", "true"]
      MyScript.start(args)
      expect(args).to eq(["foo", "bar", "--force", "true"])
    end

    it "checks unknown options" do
      expect(capture(:stderr) {
        MyScript.start(["foo", "bar", "--force", "true", "--unknown", "baz"])
      }.strip).to eq("Unknown switches '--unknown'")
    end

    it "checks unknown options except specified" do
      expect(capture(:stderr) {
        expect(MyScript.start(["with_optional", "NAME", "--omg", "--invalid"])).to eq(["NAME", {}, ["--omg", "--invalid"]])
      }.strip).to be_empty
    end
  end

  describe "attr_*" do
    it "does not add attr_reader as a command" do
      expect(capture(:stderr){ MyScript.start(["another_attribute"]) }).to match(/Could not find/)
    end

    it "does not add attr_writer as a command" do
      expect(capture(:stderr){ MyScript.start(["another_attribute=", "foo"]) }).to match(/Could not find/)
    end

    it "does not add attr_accessor as a command" do
      expect(capture(:stderr){ MyScript.start(["some_attribute"]) }).to match(/Could not find/)
      expect(capture(:stderr){ MyScript.start(["some_attribute=", "foo"]) }).to match(/Could not find/)
    end
  end
end
