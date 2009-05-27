require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'thor/tasks'

# bleh. testing private methods?
class << Thor
  public :convert_task_options
end

describe "thor" do
  describe "convert_task_options" do
    it "turns true values into a flag" do
      Thor.convert_task_options(:color => true).must == "--color"
    end
    
    it "ignores nil" do
      Thor.convert_task_options(:color => nil).must == ""
    end
    
    it "ignores false" do
      Thor.convert_task_options(:color => false).must == ""
    end
    
    it "writes --name value for anything else" do
      Thor.convert_task_options(:format => "specdoc").must == %{--format "specdoc"}
    end
  end
end
