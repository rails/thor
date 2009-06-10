require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'thor/actions'

describe Thor::Actions::CopyFile do
  before(:each) do
    ::FileUtils.rm_r(destination_root, :force => true)
  end

  def copy_file(source, destination=nil)
    @base ||= begin
      base = Object.new
      mock(base).source_root{ source_root }
      mock(base).destination_root{ destination_root }
      base
    end

    @action ||= Thor::Actions::CopyFile.new(base, source, destination || source)
  end

  describe "#source" do
    it "sets the source based on the source root" do
      copy_file("task.thor").source.must == File.join(source_root, 'task.thor')
    end
  end

  describe "#destination" do
    it "sets the destination based on the destinatino root" do
      copy_file("task.thor").destination.must == File.join(destination_root, 'task.thor')
    end
  end

  describe "#invoke!" do
    it "copies the file to the destination root" do
      copy_file("task.thor").invoke!
      File.exists?(@action.destination).must be_true
      FileUtils.identical?(@action.source, @action.destination).must be_true
    end
  end

  describe "#revoke!" do
    it "removes the destination file" do
      copy_file("task.thor").invoke!
      @action.revoke!
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
      @action.invoke!
      @action.exists?.must be_true
    end
  end

  describe "#identical?" do
    it "returns true if the destination file and is identical" do
      copy_file("task.thor")
      @action.identical?.must be_false
      @action.invoke!
      @action.identical?.must be_true
    end
  end
end
