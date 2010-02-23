require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Thor::Shell do
  def shell
    @shell ||= Thor::Base.shell.new
  end

  describe "#initialize" do
    it "sets shell value" do
      base = MyCounter.new [1, 2], { }, :shell => shell
      base.shell.must == shell
    end

    it "sets the base value on the shell if an accessor is available" do
      base = MyCounter.new [1, 2], { }, :shell => shell
      shell.base.must == base
    end
  end

  describe "#shell" do
    it "returns the shell in use" do
      MyCounter.new([1,2]).shell.must be_kind_of(Thor::Base.shell)
    end
  end

  describe "with_padding" do
    it "uses padding for inside block outputs" do
      base = MyCounter.new([1,2])
      base.with_padding do
        capture(:stdout){ base.say_status :padding, "cool" }.strip.must == "padding    cool"
      end
    end
  end
end
