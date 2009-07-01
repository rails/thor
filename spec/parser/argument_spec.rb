require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'thor/parser'

describe Thor::Argument do

  def argument(name, type=:string, default=nil, required=nil)
    @argument ||= Thor::Argument.new(name, nil, required || default.nil?, type, default)
  end

  describe "errors" do
    it "raises an error if name is not supplied" do
      lambda {
        argument(nil)
      }.must raise_error(ArgumentError, "Argument name can't be nil.")
    end

    it "raises an error if type is unknown" do
      lambda {
        argument(:task, :unknown)
      }.must raise_error(ArgumentError, "Type :unknown is not valid for arguments.")
    end

    it "raises an error if argument is required and have default values" do
      lambda {
        argument(:task, :string, "bar", true)
      }.must raise_error(ArgumentError, "An argument cannot be required and have default value.")
    end
  end

  describe "#usage" do
    it "returns usage for string types" do
      argument(:foo, :string).usage.must == "FOO"
    end

    it "returns usage for numeric types" do
      argument(:foo, :numeric).usage.must == "N"
    end

    it "returns usage for array types" do
      argument(:foo, :array).usage.must == "one two three"
    end

    it "returns usage for hash types" do
      argument(:foo, :hash).usage.must == "key:value"
    end
  end
end
