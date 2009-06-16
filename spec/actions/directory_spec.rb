require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'thor/actions'

describe Thor::Actions::Directory do
  before(:each) do
    ::FileUtils.rm_rf(destination_root)
    mock(invoker).file_name{ "rdoc" }
  end

  def invoker
    @invoker ||= MyCounter.new([], {}, { :root => destination_root })
  end

  def revoker
    @revoker ||= MyCounter.new([], {}, { :root => destination_root, :behavior => :revoke })
  end

  def exists_and_identical?(source_path, destination_path)
    %w(config.rb README).each do |file|
      source      = File.join(source_root, source_path, file)
      destination = File.join(destination_root, destination_path, file)

      File.exists?(destination).must be_true
      FileUtils.identical?(source, destination).must be_true
    end
  end

  describe "#invoke!" do
    it "copies the whole directory to the default destination" do
      capture(:stdout){ invoker.directory("doc") }
      exists_and_identical?("doc", "doc")
    end

    it "copies the whole directory to the specified destination" do
      capture(:stdout){ invoker.directory("doc", "docs") }
      exists_and_identical?("doc", "docs")
    end

    it "copies files from the source relative to the current path" do
      invoker.inside "doc" do
        capture(:stdout){ invoker.directory(".") }
      end

      exists_and_identical?("doc", "doc")
    end

    it "copies and evaluates templates" do
      capture(:stdout){ invoker.directory("doc", "docs") }

      file = File.join(destination_root, "docs", "rdoc.rb")
      File.exists?(file).must be_true
      File.read(file).must == "FOO = FOO\n"
    end

    it "copies directories" do
      capture(:stdout){ invoker.directory("doc", "docs") }

      file = File.join(destination_root, "docs", "components")
      File.exists?(file).must be_true
      File.directory?(file).must be_true
    end

    it "does not copy .empty_diretories files" do
      capture(:stdout){ invoker.directory("doc", "docs") }

      file = File.join(destination_root, "docs", "components", ".empty_directory")
      File.exists?(file).must be_false
    end

    it "logs status" do
      content = capture(:stdout){ invoker.directory("doc") }
      content.must =~ /\[CREATE\] doc\/README/
      content.must =~ /\[CREATE\] doc\/config\.rb/
      content.must =~ /\[CREATE\] doc\/rdoc\.rb/
      content.must =~ /\[CREATE\] doc\/components/
    end
  end

  describe "#revoke!" do
    it "removes the destination file" do
      capture(:stdout){ invoker.directory("doc") }
      capture(:stdout){ revoker.directory("doc") }

      file = File.join(destination_root, "doc")
      File.exists?(file).must be_false
    end
  end
end
