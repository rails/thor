require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Thor::Generator do
  it "invokes all the tasks under the generator" do
    MyScaffold.start([]).must == [ 1, 2, 3 ]
  end
end
