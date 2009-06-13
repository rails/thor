require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'thor/runner'

class MyRunner < Thor
  include Actions
end

describe Thor::Actions do
  def runner(config={})
    MyRunner.new([], {}, config.merge!(:root => destination_root))
  end

  def file
    File.join(destination_root, "foo")
  end

  describe "#initialize" do
    it "has default behavior invoke" do
      runner.behavior.must == :invoke
    end

    it "can have behavior revoke" do
      runner(:behavior => :revoke).behavior.must == :revoke
    end

    %w(skip force pretend).each do |behavior|
      it "accepts #{behavior.to_sym} as behavior" do
        thor = runner(:behavior => behavior.to_sym)
        thor.behavior.must == :invoke
        thor.options.send(:"#{behavior}?").must be_true
      end

      it "overwrites options values with configuration values" do
        thor = MyRunner.new([], { behavior => false }, :behavior => behavior.to_sym)
        thor.options.send(:"#{behavior}?").must be_true
      end
    end
  end

  describe "#source_root" do
    it "raises an error if source root is not specified" do
      lambda {
        runner.send(:source_root)
      }.must raise_error(NoMethodError, "You have to specify the class method source_root in your thor class.")
    end
  end

  describe "#inside" do
    it "executes the block inside the given folder" do
      capture(:stdout) do
        runner.inside("foo") do
          Dir.pwd.must ==  file
        end
      end
    end

    it "creates the directory if it does not exist" do
      capture(:stdout) do
        runner.inside("foo") do
          File.exists?(file).must be_true
        end
      end
    end

    it "logs status" do
      capture(:stdout) do
        runner.inside("foo") do
          File.exists?(file).must be_true
        end
      end.must == "    [INSIDE] #{file}\n"
    end

    it "does not log status if required" do
      capture(:stdout) do
        runner.inside("foo", false) do
          File.exists?(file).must be_true
        end
      end.must be_empty
    end
  end
end
