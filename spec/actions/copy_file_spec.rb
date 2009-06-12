require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'thor/actions'

describe Thor::Actions::CopyFile do
  before(:each) do
    ::FileUtils.rm_r(destination_root, :force => true)
  end

  def copy_file(source, destination=nil)
    @base ||= begin
      base = Object.new
      stub(base).source_root{ source_root }
      stub(base).destination_root{ destination_root }
      stub(base).options{ {} }
      stub(base).shell{ Thor::Shell::Basic.new }
      base
    end

    @action ||= Thor::Actions::CopyFile.new(base, source, destination || source)
  end

  def invoke!(source, destination=nil)
    capture(:stdout){ copy_file(source, destination).invoke! }
  end

  def revoke!(source, destination=nil)
    capture(:stdout){ copy_file(source, destination).revoke! }
  end

  describe "#source" do
    it "sets the source based on the source root" do
      copy_file("task.thor").source.must == File.join(source_root, 'task.thor')
    end
  end

  describe "#destination" do
    it "sets the destination based on the destination root" do
      copy_file("task.thor").destination.must == File.join(destination_root, 'task.thor')
    end
  end

  describe "#invoke!" do
    it "copies the file to the destination root" do
      invoke!("task.thor")
      File.exists?(@action.destination).must be_true
      FileUtils.identical?(@action.source, @action.destination).must be_true
    end
  end

  describe "#revoke!" do
    it "removes the destination file" do
      invoke!("task.thor")
      revoke!("task.thor")
      File.exists?(@action.destination).must be_false
    end
  end

  describe "#show" do
    it "shows file content" do
      copy_file("task.thor").show.must == File.read(File.join(source_root, "task.thor"))
    end
  end

  describe "#exists?" do
    it "returns true if the destination file exists" do
      copy_file("task.thor")
      @action.exists?.must be_false
      invoke!("task.thor")
      @action.exists?.must be_true
    end
  end

  describe "#identical?" do
    it "returns true if the destination file and is identical" do
      copy_file("task.thor")
      @action.identical?.must be_false
      invoke!("task.thor")
      @action.identical?.must be_true
    end
  end
end
