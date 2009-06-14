require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'thor/actions'

describe Thor::Actions::InjectIntoFile do
  before(:each) do
    ::FileUtils.rm_rf(destination_root)
    ::FileUtils.cp_r(source_root, destination_root)
  end

  def inject_into_file(destination, data=nil, flag=nil, options={}, &block)
    @base = begin
      base = Object.new
      base.extend Thor::Actions
      stub(base).destination_root{ destination_root }
      stub(base).options{ options }
      stub(base).shell{ @shell = Thor::Shell::Basic.new }
      base
    end

    @action = Thor::Actions::InjectIntoFile.new(base, destination, block || data, flag, !@silence)
  end

  def invoke!
    capture(:stdout){ @action.invoke! }
  end

  def revoke!
    capture(:stdout){ @action.revoke! }
  end

  def silence!
    @silence = true
  end

  describe "#invoke!" do
    it "changes the file adding content after the flag" do
      inject_into_file("doc/README", "\nmore content", :after => "__start__")
      invoke!

      file = File.join(destination_root, "doc/README")
      File.read(file).must == "__start__\nmore content\nREADME\n__end__\n"
    end

    it "changes the file adding content before the flag" do
      inject_into_file("doc/README", "more content\n", :before => "__end__")
      invoke!

      file = File.join(destination_root, "doc/README")
      File.read(file).must == "__start__\nREADME\nmore content\n__end__\n"
    end

    it "accepts data as a block" do
      inject_into_file("doc/README", nil, :before => "__end__"){ "more content\n" }
      invoke!

      file = File.join(destination_root, "doc/README")
      File.read(file).must == "__start__\nREADME\nmore content\n__end__\n"
    end

    it "shows progress information to the user" do
      inject_into_file("doc/README", "\nmore content", :after => "__start__")
      invoke!.must == "    [INJECT] doc/README\n"
    end

    it "does not show progress information if log status is false" do
      silence!
      inject_into_file("doc/README", "\nmore content", :after => "__start__")
      invoke!.must be_empty
    end

    it "does not change the file if pretending" do
      inject_into_file("doc/README", "\nmore content", { :after => "__start__" }, :pretend => true)
      invoke!

      file = File.join(destination_root, "doc/README")
      File.read(file).must == "__start__\nREADME\n__end__\n"
    end
  end

  describe "#revoke!" do
    it "deinjects the destination file after injection" do
      inject_into_file("doc/README", "\nmore content", :after => "__start__")
      invoke!
      revoke!
      file = File.join(destination_root, "doc/README")
      File.read(file).must == "__start__\nREADME\n__end__\n"
    end

    it "deinjects the destination file before injection" do
      inject_into_file("doc/README", "\nmore content", :before => "__end__")
      invoke!
      revoke!
      file = File.join(destination_root, "doc/README")
      File.read(file).must == "__start__\nREADME\n__end__\n"
    end

    it "shows progress information to the user" do
      inject_into_file("doc/README", "\nmore content", :after => "__start__")
      invoke!
      revoke!.must == "  [DEINJECT] doc/README\n"
    end
  end
end
