require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'thor/actions'

describe Thor::Actions::CopyFile do
  before(:each) do
    ::FileUtils.rm_r(destination_root, :force => true)
  end

  def copy_file(source, destination=nil, options={})
    @base = begin
      base = Object.new
      stub(base).source_root{ source_root }
      stub(base).destination_root{ destination_root }
      stub(base).options{ options }
      stub(base).shell{ @shell = Thor::Shell::Basic.new }
      base
    end

    @action = Thor::Actions::CopyFile.new(base, source, destination || source)
  end

  def invoke!
    capture(:stdout){ @action.invoke! }
  end

  def revoke!
    capture(:stdout){ @action.revoke! }
  end

  describe "#invoke!" do
    it "copies the file to the default destination" do
      copy_file("task.thor")
      invoke!
      File.exists?(File.join(destination_root, "task.thor")).must be_true
      FileUtils.identical?(@action.source, @action.destination).must be_true
    end

    it "copies the file to the specified destination" do
      copy_file("task.thor", "foo.thor")
      invoke!
      File.exists?(File.join(destination_root, "foo.thor")).must be_true
      FileUtils.identical?(@action.source, @action.destination).must be_true
    end

    it "shows created status to the user" do
      copy_file("task.thor")
      invoke!.must == "   [CREATED] task.thor\n"
    end

    it "works with files inside directories" do
      copy_file("doc/README")
      invoke!.must == "   [CREATED] doc/README\n"
    end

    describe "when file exists" do
      before(:each) do
        copy_file("task.thor")
        invoke!
      end

      describe "and is identical" do
        it "shows identical status" do
          copy_file("task.thor")
          invoke!
          invoke!.must == " [IDENTICAL] task.thor\n"
        end
      end

      describe "and is not identical" do
        before(:each) do
          File.open(File.join(destination_root, 'task.thor'), 'w'){ |f| f.write("NEWCONTENT") }
        end

        it "shows forced status to the user if force is given" do
          copy_file("task.thor", "task.thor", :force => true).must_not be_identical
          invoke!.must == "    [FORCED] task.thor\n"
        end

        it "shows skipped status to the user if skip is given" do
          copy_file("task.thor", "task.thor", :skip => true).must_not be_identical
          invoke!.must == "   [SKIPPED] task.thor\n"
        end

        it "shows conflict status to ther user" do
          copy_file("task.thor").must_not be_identical
          mock($stdin).gets{ 's' }

          content = invoke!
          content.must =~ /  \[CONFLICT\] task\.thor/
          content.must =~ /Overwrite #{File.join(destination_root, 'task.thor')}\? \(enter "h" for help\) \[Ynaqdh\]/
          content.must =~ /   \[SKIPPED\] task\.thor/
        end

        it "creates the file if the file collision menu returns true" do
          copy_file("task.thor")
          mock($stdin).gets{ 'y' }
          invoke!.must =~ /   \[FORCED\] task\.thor/
        end

        it "skips the file if the file collision menu returns false" do
          copy_file("task.thor")
          mock($stdin).gets{ 'n' }
          invoke!.must =~ /   \[SKIPPED\] task\.thor/
        end

        it "executes the block given to show file content" do
          copy_file("task.thor")
          mock($stdin).gets{ 'd' }
          mock($stdin).gets{ 'n' }
          invoke!.must =~ /\-NEWCONTENT/
        end
      end
    end
  end

  describe "#revoke!" do
    it "removes the destination file" do
      copy_file("task.thor")
      invoke!
      revoke!
      File.exists?(@action.destination).must be_false
    end
  end

  describe "#render" do
    it "shows file content" do
      copy_file("task.thor").render.must == File.read(File.join(source_root, "task.thor"))
    end
  end

  describe "#exists?" do
    it "returns true if the destination file exists" do
      copy_file("task.thor")
      @action.exists?.must be_false
      invoke!
      @action.exists?.must be_true
    end
  end

  describe "#identical?" do
    it "returns true if the destination file and is identical" do
      copy_file("task.thor")
      @action.identical?.must be_false
      invoke!
      @action.identical?.must be_true
    end
  end
end
