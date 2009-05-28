require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Thor::Generator do
  it "invokes all the tasks under the generator" do
    MyScaffold.start([]).must == [ 1, 2, 3 ]
  end

#  describe "#argument" do
#    it "sets options to the next method to be invoked" do
#      args = ["bar", "bla", "bla", "--option1", "cool"]
#      arg1, arg2, options = MyScript.start(args)
#      options.must == { "option1" => "cool" }
#    end
#
#    it "ignores default option" do
#      lambda {
#        MyScript.start(["bar", "bla", "bla"])
#      }.must raise_error(Thor::Options::Error, "no value provided for required arguments '--option1'")
#    end
#  end
#
# describe "#option" do
# end
end
