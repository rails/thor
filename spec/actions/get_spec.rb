require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'thor/actions'

describe Thor::Actions::Get do
  before(:each) do
    ::FileUtils.rm_rf(destination_root)
  end

  def get(source, destination=nil, options={}, &block)
    @base = begin
      base = Object.new
      stub(base).source_root{ source_root }
      stub(base).destination_root{ destination_root }
      stub(base).relative_to_absolute_root{ |p| p.gsub(destination_root, '.')[2..-1] }
      stub(base).options{ options }
      stub(base).shell{ @shell = Thor::Shell::Basic.new }
      base
    end

    @action = Thor::Actions::Get.new(base, source, block || destination)
  end

  def invoke!
    capture(:stdout){ @action.invoke! }
  end

  def revoke!
    capture(:stdout){ @action.revoke! }
  end

  def file
    File.join(source_root, "doc", "README")
  end

  def valid?(content, path)
    content.must == "    [CREATE] #{path}\n"
    File.exists?(File.join(destination_root, path)).must be_true
    FileUtils.identical?(@action.source, @action.destination).must be_true
  end

  describe "#invoke!" do
    it "copies the file to the given destination" do
      get(file, "doc/README")
      valid?(invoke!, "doc/README")
    end

    it "uses the source basename if no destination is given" do
      get(file)
      valid?(invoke!, "README")
    end

    it "allows the destination to be given as a block" do
      get(file) { "doc/README" }
      valid?(invoke!, "doc/README")
    end

    it "yields file content to the block" do
      get(file) do |content|
        content.must == File.read(File.join(source_root, "doc/README"))
      end
    end
  end

  describe "#revoke!" do
    it "removes the destination file" do
      get(file)
      invoke!
      revoke!
      File.exists?(@action.destination).must be_false
    end
  end

  describe "#render" do
    it "shows file content" do
      get(file).render.must == File.read(File.join(source_root, "doc/README"))
    end
  end

  describe "#exists?" do
    it "returns true if the destination file exists" do
      get(file)
      @action.exists?.must be_false
      invoke!
      @action.exists?.must be_true
    end
  end

  describe "#identical?" do
    it "returns true if the destination file and is identical" do
      get(file)
      @action.identical?.must be_false
      invoke!
      @action.identical?.must be_true
    end
  end
end
