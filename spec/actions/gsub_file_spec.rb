require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

class MyRunner < Thor
  include Actions
end

describe Thor::Actions, 'gsub_file' do
  before(:each) do
    ::FileUtils.rm_rf(destination_root)
    ::FileUtils.cp_r(source_root, destination_root)
  end

  def runner(config={})
    @runner ||= MyRunner.new([], {}, { :root => destination_root }.merge(config))
  end

  def file
    File.join(destination_root, "doc", "README")
  end

  describe "#gsub_file" do
    it "replaces the content in the file" do
      capture(:stdout){ runner.gsub_file("doc/README", "__start__", "START") }
      File.open(file).read.must == "START\nREADME\n__end__\n"
    end

    it "accepts a block" do
      capture(:stdout) do
        runner.gsub_file("doc/README", "__start__"){ |match| match.gsub('__', '').upcase  }
      end
      File.open(file).read.must == "START\nREADME\n__end__\n"
    end

    it "logs status" do
      content = capture(:stdout){ runner.gsub_file("doc/README", "__start__", "START") }
      content.must == "      [GSUB] doc/README\n"
    end

    it "does not log status if required" do
      content = capture(:stdout) do
        runner.gsub_file(file, "__", false){ |match| match * 2 }
      end
      content.must be_empty
    end
  end
end
