require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'thor/actions'

describe Thor::Actions::InjectIntoFile do
  before(:each) do
    ::FileUtils.rm_rf(destination_root)
    ::FileUtils.cp_r(source_root, destination_root)
  end

  def invoker(options={})
    @invoker ||= MyCounter.new([1,2], options, { :destination_root => destination_root })
  end

  def revoker
    @revoker ||= MyCounter.new([1,2], {}, { :destination_root => destination_root, :behavior => :revoke })
  end

  def file
    File.join(destination_root, "doc/README")
  end

  describe "#invoke!" do
    it "changes the file adding content after the flag" do
      capture(:stdout) do
        invoker.inject_into_file "doc/README", "\nmore content", :after => "__start__"
      end

      File.read(file).must == "__start__\nmore content\nREADME\n__end__\n"
    end

    it "changes the file adding content before the flag" do
      capture(:stdout) do
        invoker.inject_into_file "doc/README", "more content\n", :before => "__end__"
      end

      File.read(file).must == "__start__\nREADME\nmore content\n__end__\n"
    end

    it "accepts data as a block" do
      capture(:stdout) do
        invoker.inject_into_file "doc/README", :before => "__end__" do
          "more content\n"
        end
      end

      File.read(file).must == "__start__\nREADME\nmore content\n__end__\n"
    end

    it "logs status" do
      capture(:stdout) do 
        invoker.inject_into_file "doc/README", "\nmore content", :after => "__start__"
      end.must == "      inject  doc/README\n"
    end

    it "does not change the file if pretending" do
      invoker(:pretend => true)

      capture(:stdout) do
        invoker.inject_into_file "doc/README", "\nmore content", :after => "__start__"
      end

      File.read(file).must == "__start__\nREADME\n__end__\n"
    end
  end

  describe "#revoke!" do
    it "deinjects the destination file after injection" do
      capture(:stdout){ invoker.inject_into_file("doc/README", "\nmore content", :after => "__start__") }
      capture(:stdout){ revoker.inject_into_file("doc/README", "\nmore content", :after => "__start__") }

      File.read(file).must == "__start__\nREADME\n__end__\n"
    end

    it "deinjects the destination file before injection" do
      capture(:stdout){ invoker.inject_into_file("doc/README", "\nmore content", :after => "__start__") }
      capture(:stdout){ revoker.inject_into_file("doc/README", "\nmore content", :after => "__start__") }

      File.read(file).must == "__start__\nREADME\n__end__\n"
    end

    it "shows progress information to the user" do
      capture(:stdout){ invoker.inject_into_file("doc/README", "\nmore content", :after => "__start__") }

      capture(:stdout) do
        revoker.inject_into_file("doc/README", "\nmore content", :after => "__start__")
      end.must == "    deinject  doc/README\n"
    end
  end
end
