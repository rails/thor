require "helper"
require "thor/actions"
require "tempfile"

describe Thor::Actions::CreateLink, :unless => windows? do
  before do
    @hardlink_to = File.join(Dir.tmpdir, "linkdest.rb")
    ::FileUtils.rm_rf(destination_root)
    ::FileUtils.rm_rf(@hardlink_to)
  end

  let(:config) { {} }
  let(:options) { {} }

  let(:base) do
    base = MyCounter.new([1, 2], options, :destination_root => destination_root)
    allow(base).to receive(:file_name).and_return("rdoc")
    base
  end

  let(:tempfile) { Tempfile.new("config.rb") }

  let(:source) { tempfile.path }

  let(:destination) { "doc/config.rb" }

  let(:action) do
    Thor::Actions::CreateLink.new(base, destination, source, config)
  end

  def invoke!
    capture(:stdout) { action.invoke! }
  end

  def revoke!
    capture(:stdout) { action.revoke! }
  end

  describe "#invoke!" do
    context "specifying :symbolic => true" do
      let(:config) { {:symbolic => true} }

      it "creates a symbolic link" do
        invoke!
        destination_path = File.join(destination_root, "doc/config.rb")
        expect(File.exist?(destination_path)).to be true
        expect(File.symlink?(destination_path)).to be true
      end
    end

    context "specifying :symbolic => false" do
      let(:config) { {:symbolic => false} }
      let(:destination) { @hardlink_to }

      it "creates a hard link" do
        invoke!
        destination_path = @hardlink_to
        expect(File.exist?(destination_path)).to be true
        expect(File.symlink?(destination_path)).to be false
      end
    end

    it "creates a symbolic link by default" do
      invoke!
      destination_path = File.join(destination_root, "doc/config.rb")
      expect(File.exist?(destination_path)).to be true
      expect(File.symlink?(destination_path)).to be true
    end

    context "specifying :pretend => true" do
      let(:options) { {:pretend => true} }
      it "does not create a link" do
        invoke!
        expect(File.exist?(File.join(destination_root, "doc/config.rb"))).to be false
      end
    end

    it "shows created status to the user" do
      expect(invoke!).to eq("      create  doc/config.rb\n")
    end

    context "specifying :verbose => false" do
      let(:config) { {:verbose => false} }
      it "does not show any information" do
        expect(invoke!).to be_empty
      end
    end
  end

  describe "#identical?" do
    it "returns true if the destination link exists and is identical" do
      expect(action.identical?).to be false
      invoke!
      expect(action.identical?).to be true
    end

    context "with source path relative to destination" do
      let(:source) do
        destination_path = File.dirname(File.join(destination_root, destination))
        Pathname.new(super()).relative_path_from(Pathname.new(destination_path)).to_s
      end

      it "returns true if the destination link exists and is identical" do
        expect(action.identical?).to be false
        invoke!
        expect(action.identical?).to be true
      end
    end
  end

  describe "#revoke!" do
    it "removes the symbolic link of non-existent destination" do
      invoke!
      File.delete(tempfile.path)
      revoke!
      expect(File.symlink?(action.destination)).to be false
    end
  end
end
