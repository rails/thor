require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'thor/actions'

describe Thor::Actions::CopyFile do
  before(:each) do
    ::FileUtils.rm_rf(destination_root)
  end

  def invoker
    @invoker ||= MyCounter.new([], {}, { :root => destination_root })
  end

  def revoker
    @revoker ||= MyCounter.new([], {}, { :root => destination_root, :behavior => :revoke })
  end

  def exists_and_identical?(source, destination)
   destination = File.join(destination_root, destination)
   File.exists?(destination).must be_true

   source = File.join(source_root, source)
   FileUtils.must be_identical(source, destination)
  end

  describe "#invoke!" do
    it "copies file from source to default destination" do
      capture(:stdout){ invoker.copy_file("task.thor") }
      exists_and_identical?("task.thor", "task.thor")
    end

    it "copies file from source to the specified destination" do
      capture(:stdout){ invoker.copy_file("task.thor", "foo.thor") }
      exists_and_identical?("task.thor", "foo.thor")
    end

    it "copies file from the source relative to the current path" do
      invoker.inside("doc") do
        capture(:stdout){ invoker.copy_file("README") }
      end

      exists_and_identical?("doc/README", "doc/README")
    end

    it "logs status" do
      capture(:stdout){ invoker.copy_file("task.thor") }.must == "    [CREATE] task.thor\n"
    end
  end

  describe "#revoke!" do
    it "removes the destination file" do
      capture(:stdout){ invoker.copy_file("task.thor") }
      capture(:stdout){ revoker.copy_file("task.thor") }

      file = File.join(destination_root, "task.thor")
      File.exists?(file).must be_false
    end
  end
end
