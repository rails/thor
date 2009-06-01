require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Thor::Generator do
  describe "#start" do
    it "invokes all the tasks under the generator" do
      MyCounter.start(["1", "2", "--third", "3"]).must == [ 1, 2, 3 ]
    end

    it "uses argument default value" do
      MyCounter.start(["1", "--third", "3"]).must == [ 1, 2, 3 ]
    end

    it "invokes all the tasks under the generator and his parents" do
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

    it "raises an error when a generator task expects arguments" do
      lambda { WhinyGenerator.start }.must raise_error
    end

    it "invokes help message if any of the shortcuts is given" do
      stub(MyCounter).help
      MyCounter.start(["-h"])
    end
  end

  describe "#help" do
    before(:each) do
      @content = capture(:stdout){ MyCounter.help }
    end

    it "provides usage information" do
      @content.must =~ /my_counter N \[N\]/
    end

    it "shows global options information" do
      @content.must =~ /Options/
      @content.must =~ /\[\-\-third=N\]/
    end

    it "shows only usage if a short help is required" do
      content = capture(:stdout){ MyCounter.help(:short => true) }
      content.must =~ /my_counter N \[N\] \[\-\-third=N\]/
      content.must_not =~ /Options/
    end
  end
end
