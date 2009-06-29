require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'thor/actions'

describe Thor::Actions::Get do
  before(:each) do
    ::FileUtils.rm_rf(destination_root)
  end

  def invoker
    @invoker ||= MyCounter.new([1,2], {}, { :root => destination_root })
  end

  def revoker
    @revoker ||= MyCounter.new([1,2], {}, { :root => destination_root, :behavior => :revoke })
  end

  def exists_and_identical?(source, destination)
   destination = File.join(destination_root, destination)
   File.exists?(destination).must be_true

   source = File.join(source_root, source)
   FileUtils.must be_identical(source, destination)
  end

  describe "#invoke!" do
    it "copies file from source to the specified destination" do
      capture(:stdout){ invoker.get("doc/README", "docs/README") }
      exists_and_identical?("doc/README", "docs/README")
    end

    it "uses just the source basename as destination if none is specified" do
      capture(:stdout){ invoker.get("doc/README") }
      exists_and_identical?("doc/README", "README")
    end

    it "allows the destination to be set as a block result" do
      capture(:stdout){ invoker.get("doc/README"){ |c| "docs/README" } }
      exists_and_identical?("doc/README", "docs/README")
    end

    it "yields file content to a block" do
      capture(:stdout) do
        invoker.get("doc/README") do |content|
          content.must == "__start__\nREADME\n__end__\n"
        end
      end
    end

    it "logs status" do
      capture(:stdout){ invoker.get("doc/README", "docs/README") }.must == "      create  docs/README\n"
    end
  end

  describe "#revoke!" do
    it "removes the destination file" do
      capture(:stdout){ invoker.get("doc/README", "doc/README") }
      capture(:stdout){ revoker.get("doc/README", "doc/README") }

      file = File.join(destination_root, "doc/README")
      File.exists?(file).must be_false
    end
  end
end
