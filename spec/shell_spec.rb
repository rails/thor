require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Thor::Shell do
  describe "#initialize" do
    it "sets shell value" do
      shell = Thor::Shell::Basic.new
      base = MyCounter.new [1, 2], { }, :shell => shell
      base.shell.must == shell
    end

    it "sets the base value on the shell if an accessor is available" do
      shell = Thor::Shell::Basic.new
      base = MyCounter.new [1, 2], { }, :shell => shell
      shell.base.must == base
    end
  end

  describe "#shell" do
    it "returns the shell in use" do
      MyCounter.new([1,2]).shell.must be_kind_of(Thor::Shell::Basic)
    end
  end
end
