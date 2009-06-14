require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'thor/actions'

describe Thor::Actions::EmptyDirectory do
  before(:each) do
    ::FileUtils.rm_rf(destination_root)
  end

  def empty_directory(destination, options={})
    @base = begin
      base = Object.new
      stub(base).destination_root{ destination_root }
      stub(base).relative_to_absolute_root{ |p| p.gsub(destination_root, '.')[2..-1] }
      stub(base).options{ options }
      stub(base).shell{ @shell = Thor::Shell::Basic.new }
      base
    end

    @action = Thor::Actions::EmptyDirectory.new(base, nil, destination)
  end

  def invoke!
    capture(:stdout){ @action.invoke! }
  end

  def revoke!
    capture(:stdout){ @action.revoke! }
  end

  describe "#invoke!" do
    it "copies the file to the specified destination" do
      empty_directory("doc")
      invoke!
      File.exists?(File.join(destination_root, "doc")).must be_true
    end

    it "shows created status to the user" do
      empty_directory("doc")
      invoke!.must == "    [CREATE] doc\n"
    end

    describe "when directory exists exists" do
      it "shows identical status" do
        empty_directory("doc")
        invoke!
        invoke!.must == " [IDENTICAL] doc\n"
      end
    end
  end

  describe "#revoke!" do
    it "removes the destination file" do
      empty_directory("doc")
      invoke!
      revoke!
      File.exists?(@action.destination).must be_false
    end
  end

  describe "#render" do
    it "must not be available" do
      empty_directory("doc").must_not respond_to(:render)
    end
  end

  describe "#exists?" do
    it "returns true if the destination file exists" do
      empty_directory("doc")
      @action.exists?.must be_false
      invoke!
      @action.exists?.must be_true
    end
  end

  describe "#identical?" do
    it "returns true if the destination file and is identical" do
      empty_directory("doc")
      @action.identical?.must be_false
      invoke!
      @action.identical?.must be_true
    end
  end
end
