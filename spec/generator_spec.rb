require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Thor::Generator do
  describe "#argument" do
    it "sets a value as required and creates an accessor for it" do
      MyCounter.start(["1", "2", "--third", "3"])[0].must == 1
    end

    it "does not set a value in the options hash" do
      BrokenCounter.start(["1", "2", "--third", "3"])[0].must be_nil
    end
  end

  describe "#option" do
    it "sets options generator wise" do
      MyCounter.start(["1", "2", "--third", "3"])[2].must == 3
    end

    it "does not create an acessor for it" do
      BrokenCounter.start(["1", "2", "--third", "3"])[3].must be_false
    end
  end

  describe "#start" do
    it "invokes all the tasks under the generator" do
      MyCounter.start(["1", "2", "--third", "3"]).must == [ 1, 2, 3 ]
    end

    it "invokes all the tasks under the generator and his parents" do
      BrokenCounter.start(["1", "2", "--third", "3"]).must == [ nil, 2, 3, false, 5 ]
    end

    it "raises an error if a required param is not provided" do
      capture(:stderr) { MyCounter.start(["1", "--third", "3"]) }.must =~ /no value provided for required arguments '\-\-second'/
    end

    it "raises when an exception happens within the task call" do
      lambda { BrokenCounter.start(["1", "2", "--fail"]) }.must raise_error
    end

    it "raises an error when a generator task expects arguments" do
      pending do
        lambda { WhinyGenerator.start }.must raise_error
      end
    end
  end
end
