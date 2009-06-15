require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Thor::Group do
  describe "#start" do
    it "invokes all the tasks under the Thor group" do
      MyCounter.start(["1", "2", "--third", "3"]).must == [ 1, 2, 3 ]
    end

    it "uses argument default value" do
      MyCounter.start(["1", "--third", "3"]).must == [ 1, 2, 3 ]
    end

    it "invokes all the tasks in the Thor group and his parents" do
      BrokenCounter.start(["1", "2", "--third", "3"]).must == [ nil, 2, 3, false, 5 ]
    end

    it "raises an error if a required argument is added after a non-required" do
      lambda {
        MyCounter.argument(:foo, :type => :string)
      }.must raise_error(ArgumentError, 'You cannot have "foo" as required argument after the non-required argument "second".')
    end

    it "raises when an exception happens within the task call" do
      lambda { BrokenCounter.start(["1", "2", "--fail"]) }.must raise_error
    end

    it "raises an error when a Thor group task expects arguments" do
      lambda { WhinyGenerator.start }.must raise_error
    end

    it "invokes help message if any of the shortcuts is given" do
      stub(MyCounter).help
      MyCounter.start(["-h"])
    end
  end

  describe "#help" do
    before(:each) do
      @content = capture(:stdout){ MyCounter.help(Thor::Base.shell.new) }
    end

    it "provides usage information" do
      @content.must =~ /my_counter N \[N\]/
    end

    it "shows description" do
      @content.must =~ /Description:/
      @content.must =~ /This generator run three tasks: one, two and three./
    end

    it "shows inherited description" do
      @content = capture(:stdout){ BrokenCounter.help(Thor::Base.shell.new) }
      @content.must =~ /Description:/
      @content.must =~ /This generator run three tasks: one, two and three./
    end

    it "shows global options information" do
      @content.must =~ /Options/
      @content.must =~ /\[\-\-third=N\]/
    end

    it "shows global options description" do
      @content.must =~ /# The third argument\./
    end

    it "shows only usage if a short help is required" do
      content = capture(:stdout){ MyCounter.help(Thor::Base.shell.new, :short => true) }
      content.must =~ /my_counter N \[N\]/
      content.must_not =~ /Options/
    end
  end
end
