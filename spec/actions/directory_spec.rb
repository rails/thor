require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'thor/actions'

describe Thor::Actions::Directory do
  before(:each) do
    ::FileUtils.rm_rf(destination_root)
    invoker.stub!(:file_name).and_return("rdoc")
  end

  def invoker
    @invoker ||= WhinyGenerator.new([1,2], {}, { :destination_root => destination_root })
  end

  def revoker
    @revoker ||= WhinyGenerator.new([1,2], {}, { :destination_root => destination_root, :behavior => :revoke })
  end

  def invoke!(*args, &block)
    capture(:stdout){ invoker.directory(*args, &block) }
  end

  def revoke!(*args, &block)
    capture(:stdout){ revoker.directory(*args, &block) }
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
    it "raises an error if the source does not exist" do
      lambda {
        invoke! "unknown"
      }.must raise_error(Thor::Error, /Could not find "unknown" in any of your source paths/)
    end

    it "copies the whole directory recursively to the default destination" do
      invoke! "doc"
      exists_and_identical?("doc", "doc")
    end

    it "copies the whole directory recursively to the specified destination" do
      invoke! "doc", "docs"
      exists_and_identical?("doc", "docs")
    end

    it "copies only the first level files if recursive" do
      invoke! ".", "tasks", :recursive => false

      file = File.join(destination_root, "tasks", "group.thor")
      File.exists?(file).must be_true

      file = File.join(destination_root, "tasks", "doc")
      File.exists?(file).must be_false

      file = File.join(destination_root, "tasks", "doc", "README")
      File.exists?(file).must be_false
    end

    it "copies files from the source relative to the current path" do
      invoker.inside "doc" do
        invoke! "."
      end
      exists_and_identical?("doc", "doc")
    end

    it "copies and evaluates templates" do
      invoke! "doc", "docs"
      file = File.join(destination_root, "docs", "rdoc.rb")
      File.exists?(file).must be_true
      File.read(file).must == "FOO = FOO\n"
    end

    it "copies directories" do
      invoke! "doc", "docs"
      file = File.join(destination_root, "docs", "components")
      File.exists?(file).must be_true
      File.directory?(file).must be_true
    end

    it "does not copy .empty_diretories files" do
      invoke! "doc", "docs"
      file = File.join(destination_root, "docs", "components", ".empty_directory")
      File.exists?(file).must be_false
    end

    it "copies directories even if they are empty" do
      invoke! "doc/components", "docs/components"
      file = File.join(destination_root, "docs", "components")
      File.exists?(file).must be_true
    end

    it "does not copy empty directories twice" do
      content = invoke!("doc/components", "docs/components")
      content.must_not =~ /exist/
    end

    it "logs status" do
      content = invoke!("doc")
      content.must =~ /create  doc\/README/
      content.must =~ /create  doc\/config\.rb/
      content.must =~ /create  doc\/rdoc\.rb/
      content.must =~ /create  doc\/components/
    end

    it "yields a block" do
      checked = false
      invoke!("doc") do |content|
        checked ||= !!(content =~ /FOO/)
      end
      checked.must be_true
    end
  end

  describe "#revoke!" do
    it "removes the destination file" do
      invoke! "doc"
      revoke! "doc"

      File.exists?(File.join(destination_root, "doc", "README")).must be_false
      File.exists?(File.join(destination_root, "doc", "config.rb")).must be_false
      File.exists?(File.join(destination_root, "doc", "components")).must be_false
    end
  end
end
