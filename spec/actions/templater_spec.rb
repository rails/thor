require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'thor/actions'

class Templater < Thor::Actions::Templater
  def render
    @render ||= File.read(source)
  end
end

describe Thor::Actions::Templater do
  before(:each) do
    ::FileUtils.rm_rf(destination_root)
  end

  def templater(source, destination=nil, options={})
    @base = begin
      base = Object.new
      stub(base).file_name{ "rdoc" }
      stub(base).source_root{ source_root }
      stub(base).relative_root{ "" }
      stub(base).destination_root{ destination_root }
      stub(base).relative_to_absolute_root{ |p| p.gsub(destination_root, '.')[2..-1] }
      stub(base).options{ options }
      stub(base).shell{ @shell = Thor::Shell::Basic.new }
      base
    end

    @action = Templater.new(base, source, destination || source, !@silence)
  end

  def invoke!
    capture(:stdout){ @action.invoke! }
  end

  def revoke!
    capture(:stdout){ @action.revoke! }
  end

  def silence!
    @silence = true
  end

  describe "#source" do
    it "sets the source based on the source root" do
      templater('task.thor').source.must == File.join(source_root, 'task.thor')
    end
  end

  describe "#destination" do
    it "uses the source as default destination" do
      templater('task.thor').destination.must == File.join(destination_root, 'task.thor')
    end

    it "allows the destination to be set" do
      templater('task.thor', 'foo.thor').destination.must == File.join(destination_root, 'foo.thor')
    end

    it "sets the destination based on the destination root" do
      templater('task.thor', 'task.thor').destination.must == File.join(destination_root, 'task.thor')
    end
  end

  describe "#relative_destination" do
    it "stores the relative destination given" do
      templater('task.thor').relative_destination.must == 'task.thor'
    end
  end

  describe "#invoke!" do
    it "creates a file" do
      templater("doc/config.rb")
      invoke!
      File.exists?(File.join(destination_root, "doc/config.rb")).must be_true
    end

    it "does not create a file if pretending" do
      templater("doc/config.rb", "doc/config.rb", :pretend => true)
      invoke!
      File.exists?(File.join(destination_root, "doc/config.rb")).must be_false
    end

    it "shows created status to the user" do
      templater("doc/config.rb")
      invoke!.must == "      create  doc/config.rb\n"
    end

    it "does not show any information if log status is false" do
      silence!
      templater("doc/config.rb")
      invoke!.must be_empty
    end

    it "returns the destination" do
      capture(:stdout) do
        templater("doc/config.rb").invoke!.must == File.join(destination_root, "doc/config.rb")
      end
    end

    it "converts encoded instructions" do
      templater("doc/%file_name%.rb.tt")
      invoke!
      File.exists?(File.join(destination_root, "doc/rdoc.rb.tt")).must be_true
    end

    describe "when file exists" do
      before(:each) do
        templater("doc/config.rb")
        invoke!
      end

      describe "and is identical" do
        it "shows identical status" do
          templater("doc/config.rb")
          invoke!
          invoke!.must == "   identical  doc/config.rb\n"
        end
      end

      describe "and is not identical" do
        before(:each) do
          File.open(File.join(destination_root, 'doc/config.rb'), 'w'){ |f| f.write("FOO = 3") }
        end

        it "shows forced status to the user if force is given" do
          templater("doc/config.rb", "doc/config.rb", :force => true).must_not be_identical
          invoke!.must == "       force  doc/config.rb\n"
        end

        it "shows skipped status to the user if skip is given" do
          templater("doc/config.rb", "doc/config.rb", :skip => true).must_not be_identical
          invoke!.must == "        skip  doc/config.rb\n"
        end

        it "shows conflict status to ther user" do
          templater("doc/config.rb").must_not be_identical
          mock($stdin).gets{ 's' }
          file = File.join(destination_root, 'doc/config.rb')

          content = invoke!
          content.must =~ /conflict  doc\/config\.rb/
          content.must =~ /Overwrite #{file}\? \(enter "h" for help\) \[Ynaqdh\]/
          content.must =~ /skip  doc\/config\.rb/
        end

        it "creates the file if the file collision menu returns true" do
          templater("doc/config.rb")
          mock($stdin).gets{ 'y' }
          invoke!.must =~ /force  doc\/config\.rb/
        end

        it "skips the file if the file collision menu returns false" do
          templater("doc/config.rb")
          mock($stdin).gets{ 'n' }
          invoke!.must =~ /skip  doc\/config\.rb/
        end

        it "executes the block given to show file content" do
          templater("doc/config.rb")
          mock($stdin).gets{ 'd' }
          mock($stdin).gets{ 'n' }
          invoke!.must =~ /\-FOO = 3/
        end
      end
    end
  end

  describe "#revoke!" do
    it "removes the destination file" do
      templater("doc/config.rb")
      invoke!
      revoke!
      File.exists?(@action.destination).must be_false
    end

    it "does not raise an error if the file does not exist" do
      templater("doc/config.rb")
      revoke!
      File.exists?(@action.destination).must be_false
    end
  end

  describe "#exists?" do
    it "returns true if the destination file exists" do
      templater("doc/config.rb")
      @action.exists?.must be_false
      invoke!
      @action.exists?.must be_true
    end
  end

  describe "#identical?" do
    it "returns true if the destination file and is identical" do
      templater("doc/config.rb")
      @action.identical?.must be_false
      invoke!
      @action.identical?.must be_true
    end
  end
end
