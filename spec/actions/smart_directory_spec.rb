require 'helper'
require 'thor/actions'

describe Thor::Actions::SmartDirectory do
  let(:template_root) { File.join source_root, "dirtest" }
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
    capture(:stdout){ invoker.smart_directory(*args, &block) }
  end

  def revoke!(*args, &block)
    capture(:stdout){ revoker.smart_directory(*args, &block) }
  end

  def exists_and_identical?(source_path, destination_path)
    %w(config.rb README).each do |file|
      source      = File.join(source_root, source_path, file)
      destination = File.join(destination_root, destination_path, file)

      expect(File.exists?(destination)).to be_true
      expect(FileUtils.identical?(source, destination)).to be_true
    end
  end

  def all_files_and_folders_accounted_for?(source_path, destination_path)
    source_files = Dir[File.join(source_root, source_path, "**", "*")].map do |fn|
      fn.chomp(".tt").chomp(".zc")
    end.uniq.sort
    destination_files = Dir[File.join(destination_root, destination_path, "**", "*")].sort

    expect(source_files.count).to eq destination_files.count
    source_files.zip(destination_files).each do |s_n_d|
      source = s_n_d.first.gsub File.join(source_root, source_path), ""
      destiny = s_n_d.last.gsub File.join(destination_root, destination_path), ""
      expect(source).to eq destiny
    end
  end

  def templates_contain_external_content?(source_path, destination_path)
    templatable_files = Dir[File.join(source_root, source_path, "**", "*.tt")]
    templated_files = templatable_files.map do |fn|
      fn.gsub File.join(source_root, source_path), File.join(destination_root, destination_path)
    end.map { |fn| fn.chomp(".tt") }

    templated_files.each do |tf|
      expect(File.exists? tf).to be_true
      expect(File.read(tf) =~ /this is content/).to be_true
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

    it "copies the whole directory recursively to the specified destination" do
      invoke! "doc", "docs"
      exists_and_identical?("doc", "docs")
    end
    name_thing = "copying over the entire directory "
    name_thing += "templating files that end in .tt"
    name_thing += "dumping contents from .cz files into .tt files" 
    it name_thing do
      invoke! "dirtest", "dirtests"
      all_files_and_folders_accounted_for?("dirtest", "dirtests")
      templates_contain_external_content?("dirtest", "dirtests")
    end

  end
end