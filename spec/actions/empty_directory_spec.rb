require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'thor/actions'

describe Thor::Actions::EmptyDirectory do
  before(:each) do
    ::FileUtils.rm_rf(destination_root)
  end

  def empty_directory(destination, options={})
    @action = Thor::Actions::EmptyDirectory.new(base, destination)
  end

  def invoke!
    capture(:stdout){ @action.invoke! }
  end

  def revoke!
    capture(:stdout){ @action.revoke! }
  end

  def base
    @base ||= MyCounter.new([1,2], options, { :destination_root => destination_root })
  end

  describe "#destination" do
    it "returns the full destination with the destination_root" do
      empty_directory('doc').destination.must == File.join(destination_root, 'doc')
    end

    it "takes relative root into account" do
      base.inside('doc') do
        empty_directory('contents').destination.must == File.join(destination_root, 'doc', 'contents')
      end
    end
  end

  describe "#relative_destination" do
    it "returns the relative destination to the original destination root" do
      base.inside('doc') do
        empty_directory('contents').relative_destination.must == 'doc/contents'
      end
    end
  end

  describe "#given_destination" do
    it "returns the destination supplied by the user" do
      base.inside('doc') do
        empty_directory('contents').given_destination.must == 'contents'
      end
    end
  end

  describe "#invoke!" do
    it "copies the file to the specified destination" do
      empty_directory("doc")
      invoke!
      File.exists?(File.join(destination_root, "doc")).must be_true
    end

    it "shows created status to the user" do
      empty_directory("doc")
      invoke!.must == "      create  doc\n"
    end

    describe "when directory exists" do
      it "shows exist status" do
        empty_directory("doc")
        invoke!
        invoke!.must == "       exist  doc\n"
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

  describe "#exists?" do
    it "returns true if the destination file exists" do
      empty_directory("doc")
      @action.exists?.must be_false
      invoke!
      @action.exists?.must be_true
    end
  end
end
