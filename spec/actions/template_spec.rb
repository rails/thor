require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'thor/actions'

describe Thor::Actions::Template do
  before(:each) do
    ::FileUtils.rm_rf(destination_root)
  end

  def invoker
    @invoker ||= MyCounter.new([], {}, { :root => destination_root })
  end

  def revoker
    @revoker ||= MyCounter.new([], {}, { :root => destination_root, :behavior => :revoke })
  end

  describe "#invoke!" do
    it "evaluates the template given as source" do
      invoker.instance_variable_set("@klass", "Config")
      capture(:stdout){ invoker.template("doc/config.rb") }

      file = File.join(destination_root, "doc/config.rb")
      File.read(file).must == "class Config; end\n"
    end

    it "copies the template to the specified destination" do
      capture(:stdout){ invoker.template("doc/config.rb", "doc/configuration.rb") }

      file = File.join(destination_root, "doc/configuration.rb")
      File.exists?(file).must be_true
    end

    it "removes .tt from source if no destination is given" do
      mock(invoker).file_name{ "rdoc" }
      capture(:stdout){ invoker.template("doc/%file_name%.rb.tt") }

      file = File.join(destination_root, "doc/rdoc.rb")
      File.exists?(file).must be_true
    end

    it "logs status" do
      capture(:stdout){ invoker.template("doc/config.rb") }.must == "    [CREATE] doc/config.rb\n"
    end
  end

  describe "#revoke!" do
    it "removes the destination file" do
      capture(:stdout){ invoker.template("doc/config.rb") }
      capture(:stdout){ revoker.template("doc/config.rb") }

      file = File.join(destination_root, "doc/config.rb")
      File.exists?(file).must be_false
    end
  end
end
