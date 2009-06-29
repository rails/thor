require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'thor/actions'

describe Thor::Actions::CreateFile do
  before(:each) do
    ::FileUtils.rm_rf(destination_root)
  end

  def invoker
    @invoker ||= MyCounter.new([1,2], {}, { :root => destination_root })
  end

  def revoker
    @revoker ||= MyCounter.new([1,2], {}, { :root => destination_root, :behavior => :revoke })
  end

  def file
    File.join(destination_root, "foo.thor")
  end

  describe "#invoke!" do
    it "creates a file in the given destination" do
      capture(:stdout){ invoker.create_file("foo.thor") }
      File.exists?(file).must be_true
    end

    it "creates a file with the given data" do
      capture(:stdout){ invoker.create_file("foo.thor", "BAR") }
      File.read(file).must == "BAR"
    end

    it "creates a file with content returned from a block" do
      capture(:stdout){ invoker.create_file("foo.thor"){ "BAR" } }
      File.read(file).must == "BAR"
    end

    it "logs status" do
      capture(:stdout){ invoker.create_file("foo.thor") }.must == "      create  foo.thor\n"
    end
  end

  describe "#revoke!" do
    it "removes the destination file" do
      capture(:stdout){ invoker.create_file("foo.thor") }
      capture(:stdout){ revoker.create_file("foo.thor") }
      File.exists?(file).must be_false
    end
  end
end
