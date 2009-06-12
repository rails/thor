require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'thor/runner'

describe Thor::Actions do
  describe "#initialize" do
    it "has default behavior invoke" do
      Thor::Runner.new.behavior.must == :invoke
    end

    it "can have behavior revoke" do
      Thor::Runner.new([], {}, :behavior => :revoke).behavior.must == :revoke
    end

    %w(skip force pretend).each do |behavior|
      it "accepts #{behavior.to_sym} as behavior" do
        thor = Thor::Runner.new([], {}, :behavior => behavior.to_sym)
        thor.behavior.must == :invoke
        thor.options.send(:"#{behavior}?").must be_true
      end

      it "overwrites options values with configuration values" do
        thor = Thor::Runner.new([], { behavior => false }, :behavior => behavior.to_sym)
        thor.options.send(:"#{behavior}?").must be_true
      end
    end
  end

  describe "source_root" do
    it "raises an error if source root is not specified" do
      lambda {
        Thor::Runner.new.send(:source_root)
      }.must raise_error(NoMethodError, "You have to specify the class method source_root in your thor class.")
    end
  end
end
