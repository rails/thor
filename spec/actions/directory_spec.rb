require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'thor/actions'

describe Thor::Actions::Directory do
  before do
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

      expect(File.exists?(destination)).to be_true
      expect(FileUtils.identical?(source, destination)).to be_true
    end
  end

  describe "#invoke!" do
    it "raises an error if the source does not exist" do
      expect {
        invoke! "unknown"
      }.to raise_error(Thor::Error, /Could not find "unknown" in any of your source paths/)
    end

    it "does not create a directory in pretend mode" do
      invoke! "doc", "ghost", :pretend => true
      expect(File.exists?("ghost")).to be_false
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
      expect(File.exists?(file)).to be_true

      file = File.join(destination_root, "tasks", "doc")
      expect(File.exists?(file)).to be_false

      file = File.join(destination_root, "tasks", "doc", "README")
      expect(File.exists?(file)).to be_false
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
      expect(File.exists?(file)).to be_true
      expect(File.read(file)).to eq("FOO = FOO\n")
    end

    it "copies directories and preserved file mode" do
      invoke! "preserve", "preserved", :mode => :preserve
      original = File.join(source_root, "preserve", "script.sh")
      copy = File.join(destination_root, "preserved", "script.sh")
      expect(File.stat(original).mode).to eq(File.stat(copy).mode)
    end

    it "copies directories" do
      invoke! "doc", "docs"
      file = File.join(destination_root, "docs", "components")
      expect(File.exists?(file)).to be_true
      expect(File.directory?(file)).to be_true
    end

    it "does not copy .empty_directory files" do
      invoke! "doc", "docs"
      file = File.join(destination_root, "docs", "components", ".empty_directory")
      expect(File.exists?(file)).to be_false
    end

    it "copies directories even if they are empty" do
      invoke! "doc/components", "docs/components"
      file = File.join(destination_root, "docs", "components")
      expect(File.exists?(file)).to be_true
    end

    it "does not copy empty directories twice" do
      content = invoke!("doc/components", "docs/components")
      expect(content).not_to match(/exist/)
    end

    it "logs status" do
      content = invoke!("doc")
      expect(content).to match(/create  doc\/README/)
      expect(content).to match(/create  doc\/config\.rb/)
      expect(content).to match(/create  doc\/rdoc\.rb/)
      expect(content).to match(/create  doc\/components/)
    end

    it "yields a block" do
      checked = false
      invoke!("doc") do |content|
        checked ||= !!(content =~ /FOO/)
      end
      expect(checked).to be_true
    end

    it "works with glob characters in the path" do
      content = invoke!("app{1}")
      expect(content).to match(/create  app\{1\}\/README/)
    end
  end

  describe "#revoke!" do
    it "removes the destination file" do
      invoke! "doc"
      revoke! "doc"

      expect(File.exists?(File.join(destination_root, "doc", "README"))).to be_false
      expect(File.exists?(File.join(destination_root, "doc", "config.rb"))).to be_false
      expect(File.exists?(File.join(destination_root, "doc", "components"))).to be_false
    end

    it "works with glob characters in the path" do
      invoke! "app{1}"
      expect(File.exists?(File.join(destination_root, "app{1}", "README"))).to be_true

      revoke! "app{1}"
      expect(File.exists?(File.join(destination_root, "app{1}", "README"))).to be_false
    end
  end
end
