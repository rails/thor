require "helper"

describe Thor::Command do
  def command(options = {}, usage = "can_has")
    options.each do |key, value|
      options[key] = Thor::Option.parse(key, value)
    end

    @command ||= Thor::Command.new(:can_has, "I can has cheezburger", "I can has cheezburger\nLots and lots of it", nil, usage, options)
  end

  describe "#formatted_usage" do
    it "includes namespace within usage" do
      object = Struct.new(:namespace, :arguments).new("foo", [])
      expect(command(bar: :required).formatted_usage(object)).to eq("foo:can_has --bar=BAR")
    end

    it "includes subcommand name within subcommand usage" do
      object = Struct.new(:namespace, :arguments).new("main:foo", [])
      expect(command(bar: :required).formatted_usage(object, false, true)).to eq("foo can_has --bar=BAR")
    end

    it "removes default from namespace" do
      object = Struct.new(:namespace, :arguments).new("default:foo", [])
      expect(command(bar: :required).formatted_usage(object)).to eq(":foo:can_has --bar=BAR")
    end

    it "injects arguments into usage" do
      options = {required: true, type: :string}
      object = Struct.new(:namespace, :arguments).new("foo", [Thor::Argument.new(:bar, options)])
      expect(command(foo: :required).formatted_usage(object)).to eq("foo:can_has BAR --foo=FOO")
    end

    it "allows multiple usages" do
      object = Struct.new(:namespace, :arguments).new("foo", [])
      expect(command({bar: :required}, ["can_has FOO", "can_has BAR"]).formatted_usage(object, false)).to eq("can_has FOO --bar=BAR\ncan_has BAR --bar=BAR")
    end
  end

  describe "#dynamic" do
    it "creates a dynamic command with the given name" do
      expect(Thor::DynamicCommand.new("command").name).to eq("command")
      expect(Thor::DynamicCommand.new("command").description).to eq("A dynamically-generated command")
      expect(Thor::DynamicCommand.new("command").usage).to eq("command")
      expect(Thor::DynamicCommand.new("command").options).to eq({})
    end

    it "does not invoke an existing method" do
      dub = double
      expect(dub.class).to receive(:handle_no_command_error).with("to_s")
      Thor::DynamicCommand.new("to_s").run(dub)
    end
  end

  describe "#dup" do
    it "dup options hash" do
      command = Thor::Command.new("can_has", nil, nil, nil, nil, foo: true, bar: :required)
      command.dup.options.delete(:foo)
      expect(command.options[:foo]).to be
    end
  end

  describe "#run" do
    it "runs a command by calling a method in the given instance" do
      dub = double
      expect(dub).to receive(:can_has) { |*args| args }
      expect(command.run(dub, [1, 2, 3])).to eq([1, 2, 3])
    end

    it "raises an error if the method to be invoked is private" do
      klass = Class.new do
        def self.handle_no_command_error(name)
          name
        end

        def can_has
          "fail"
        end
        private :can_has
      end

      expect(command.run(klass.new)).to eq("can_has")
    end
  end
end
