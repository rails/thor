require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../lib/thor/generator.rb')

class MyScaffold < Thor::Generator
  desc "myscaffold", "my customized scaffold"

  def zoo
    1
  end

  def animal
    2
  end

  def insect
    3
  end
end

describe Thor::Generator do

  it "invokes all the tasks under the generator" do
    MyScaffold.start([]).must == [ 1, 2, 3 ]
  end
  
end
