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

    it "does not replace if pretending" do
      capture(:stdout){ runner(:behavior => :pretend).gsub_file("doc/README", "__start__", "START") }
      File.open(file).read.must == "__start__\nREADME\n__end__\n"
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
      capture(:stdout) do
        runner.gsub_file(file, "__", false){ |match| match * 2 }
      end.must be_empty
    end
  end

  describe "#append_file" do
    it "appends content to the file" do
      capture(:stdout){ runner.append_file("doc/README", "END\n") }
      File.open(file).read.must == "__start__\nREADME\n__end__\nEND\n"
    end

    it "does not append if pretending" do
      capture(:stdout){ runner(:behavior => :pretend).append_file("doc/README", "END\n") }
      File.open(file).read.must == "__start__\nREADME\n__end__\n"
    end

    it "accepts a block" do
      capture(:stdout) do
        runner.append_file("doc/README"){ "END\n" }
      end
      File.open(file).read.must == "__start__\nREADME\n__end__\nEND\n"
    end

    it "logs status" do
      content = capture(:stdout){ runner.append_file("doc/README", "END") }
      content.must == "    [APPEND] doc/README\n"
    end

    it "does not log status if required" do
      capture(:stdout) do
        runner.append_file("doc/README", nil, false){ "END" }
      end.must be_empty
    end
  end

  describe "#prepend_file" do
    it "prepends content to the file" do
      capture(:stdout){ runner.prepend_file("doc/README", "START\n") }
      File.open(file).read.must == "START\n__start__\nREADME\n__end__\n"
    end

    it "does not prepend if pretending" do
      capture(:stdout){ runner(:behavior => :pretend).prepend_file("doc/README", "START\n") }
      File.open(file).read.must == "__start__\nREADME\n__end__\n"
    end

    it "accepts a block" do
      capture(:stdout) do
        runner.prepend_file("doc/README"){ "START\n" }
      end
      File.open(file).read.must == "START\n__start__\nREADME\n__end__\n"
    end

    it "logs status" do
      content = capture(:stdout){ runner.prepend_file("doc/README", "START") }
      content.must == "   [PREPEND] doc/README\n"
    end

    it "does not log status if required" do
      capture(:stdout) do
        runner.prepend_file("doc/README", nil, false){ "START" }
      end.must be_empty
    end
  end
end
