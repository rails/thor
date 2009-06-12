require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'thor/actions'

describe Thor::Actions::AddFile do
  before(:each) do
    ::FileUtils.rm_rf(destination_root)
  end

  def add_file(destination, data=nil, options={}, &block)
    @base = begin
      base = Object.new
      stub(base).destination_root{ destination_root }
      stub(base).options{ options }
      stub(base).shell{ @shell = Thor::Shell::Basic.new }
      base
    end

    @action = Thor::Actions::AddFile.new(base, destination, data, &block)
  end

  def invoke!
    capture(:stdout){ @action.invoke! }
  end

  def revoke!
    capture(:stdout){ @action.revoke! }
  end

  describe "#invoke!" do
    it "creates a file in the given destination with the given content" do
      add_file("doc/USAGE", "just use it")
      invoke!

      file = File.join(destination_root, "doc/USAGE")
      File.exists?(file).must be_true
      File.read(file).must == "just use it"
    end
  end

  describe "#revoke!" do
    it "removes the destination file" do
      add_file("doc/USAGE", "just use it")
      invoke!
      revoke!
      File.exists?(@action.destination).must be_false
    end
  end

  describe "#render" do
    it "shows given data" do
      add_file("doc/USAGE", "just use it").render.must == "just use it"
    end

    it "shows the result of the given block" do
      add_file("doc/USAGE"){ "just use it" }.render.must == "just use it"
    end
  end

  describe "#exists?" do
    it "returns true if the destination file exists" do
      add_file("doc/USAGE", "just use it")
      @action.exists?.must be_false
      invoke!
      @action.exists?.must be_true
    end
  end

  describe "#identical?" do
    it "returns true if the destination file and is identical" do
      add_file("doc/USAGE", "just use it")
      @action.identical?.must be_false
      invoke!
      @action.identical?.must be_true
    end
  end
end
