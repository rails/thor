require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'thor/actions'

describe Thor::Actions::CopyFile do
  before(:each) do
    ::FileUtils.rm_rf(destination_root)
  end

  def copy_file(source, destination=nil, options={})
    @base = begin
      base = Object.new
      stub(base).file_name { "rdoc" }
      stub(base).source_root{ source_root }
      stub(base).destination_root{ destination_root }
      stub(base).relative_to_absolute_root{ |p| p.gsub(destination_root, '.')[2..-1] }
      stub(base).options{ options }
      stub(base).shell{ @shell = Thor::Shell::Basic.new }
      base
    end

    @action = Thor::Actions::CopyFile.new(base, source, destination || source)
  end

  def invoke!
    capture(:stdout){ @action.invoke! }
  end

  def revoke!
    capture(:stdout){ @action.revoke! }
  end

  def valid?(content, path)
    content.must == "    [CREATE] #{path}\n"
    File.exists?(File.join(destination_root, path)).must be_true
    FileUtils.identical?(@action.source, @action.destination).must be_true
  end

  describe "#invoke!" do
    it "copies the file to the default destination" do
      copy_file("task.thor")
      valid?(invoke!, "task.thor")
    end

    it "copies the file to the specified destination" do
      copy_file("task.thor", "foo.thor")
      valid?(invoke!, "foo.thor")
    end

    it "works with files inside directories" do
      copy_file("doc/README")
      valid?(invoke!, "doc/README")
    end

    it "converts encoded instructions" do
      copy_file("doc/%file_name%.rb.tt")
      valid?(invoke!, "doc/rdoc.rb.tt")
    end
  end

  describe "#revoke!" do
    it "removes the destination file" do
      copy_file("task.thor")
      invoke!
      revoke!
      File.exists?(@action.destination).must be_false
    end
  end

  describe "#render" do
    it "shows file content" do
      copy_file("task.thor").render.must == File.read(File.join(source_root, "task.thor"))
    end
  end

  describe "#exists?" do
    it "returns true if the destination file exists" do
      copy_file("task.thor")
      @action.exists?.must be_false
      invoke!
      @action.exists?.must be_true
    end
  end

  describe "#identical?" do
    it "returns true if the destination file and is identical" do
      copy_file("task.thor")
      @action.identical?.must be_false
      invoke!
      @action.identical?.must be_true
    end
  end
end
