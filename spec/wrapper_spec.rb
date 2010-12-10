require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'thor/wrapper'

describe Thor::Wrapper do
  before(:each) do
    Wrapping.wraps WRAPPED_COMMAND
    @wrapper = Wrapping.new
  end

  # Behavior of Thor::Wrapper instance methods

  describe "#parent" do
    it "invokes the Class method" do
      Wrapping.should_receive(:parent).once
      @wrapper.parent
    end
    
    it "returns the name of the parent command" do
      @wrapper.parent.should == WRAPPED_COMMAND
    end
  end

  describe "#parent_path" do
    it "invokes the Class method" do
      Wrapping.should_receive(:parent_path).once
      @wrapper.parent_path
    end

    it "returns the path of the parent command" do
      @wrapper.parent_path.should == WRAPPED_PATH
    end
  end

  describe "#forward" do
    before(:each) do
      Object.stub!(:system).with("#{WRAPPED_COMMAND} foo bar").and_return(true)
    end
    
    it "invokes the Class method" do
      Wrapping.should_receive(:forward).once
      @wrapper.forward("foo", "bar")
    end

    it "forwards a command to the parent command and returns true if it succeeds" do
      @wrapper.forward("foo", "bar").should == true
    end
  end

  describe "#wrap" do
    it "invokes the Class method" do
      Wrapping.should_receive(:wrap).once
      @wrapper.wrap("foo", "bar")
    end

    it "forwards a command to the parent command and returns the output" do
      # Note: mock for :` is contained in spec_wrapper
      @wrapper.wrap("foo", "bar").should == "burble\nburble\n"
    end
  end
  
  # Behavior of Thor::Wrapper class methods:

  describe ".parent" do
    it "returns the name of the parent command" do
      Wrapping.parent.should == WRAPPED_COMMAND
    end
  end

  describe ".parent_path" do
    it "returns the path of the parent command" do
      Wrapping.parent_path.should == WRAPPED_PATH
    end
  end
  
  describe ".wraps" do
    it "sets the name of the parent command" do
      Wrapping.wraps "foo"
      @wrapper.parent.should == "foo"
    end
  end

  describe ".forward" do
    before :each do
      Object.stub!(:system).with("#{WRAPPED_COMMAND} foo bar").and_return(true)
    end
    
    it "invokes check_forward" do
      Wrapping.should_receive(:check_forward).once
      Wrapping.forward("foo", "bar")
    end
    
    it "forwards a command to the parent command and returns true if it succeeds" do
      Wrapping.forward("foo", "bar").should == true
    end
  end

  describe ".wrap" do
    it "invokes check_forward" do
      Wrapping.should_receive(:check_forward).once
      Wrapping.wrap("foo", "bar")
    end

    it "forwards a command to the parent command and returns the output" do
      # Note: mock for :` is contained in spec_wrapper
      Wrapping.wrap("foo", "bar").should == "burble\nburble\n"
    end
  end
  
  describe ".check_forward" do
    it "fails if the parent does not exist" do
      File.stub!(:exists?).with(WRAPPED_PATH).and_return(false)
      File.stub!(:executable?).with(WRAPPED_PATH).and_return(true)
      File.stub!(:expand_path).with($0).and_return("foo")
      lambda { Wrapping.check_forward }.should raise_error(Thor::Error)
    end

    it "fails if the parent is not executable" do
      File.stub!(:exists?).with(WRAPPED_PATH).and_return(true)
      File.stub!(:executable?).with(WRAPPED_PATH).and_return(false)
      File.stub!(:expand_path).with($0).and_return("foo")
      lambda { Wrapping.check_forward }.should raise_error(Thor::Error)
    end

    it "fails if the parent is recursive" do
      File.stub!(:exists?).with(WRAPPED_PATH).and_return(true)
      File.stub!(:executable?).with(WRAPPED_PATH).and_return(true)
      File.stub!(:expand_path).with($0).and_return(Wrapping.parent_path)
      lambda { Wrapping.check_forward }.should raise_error(Thor::Error)
    end

    it "succeeds if the parent exists, is executable and is not recursive" do
      File.stub!(:exists?).with(WRAPPED_PATH).and_return(true)
      File.stub!(:executable?).with(WRAPPED_PATH).and_return(true)
      File.stub!(:expand_path).with($0).and_return("foo")
      lambda { Wrapping.check_forward }.should_not raise_error
    end
  end
  
  describe "#help" do
    def shell
      @shell ||= Thor::Base.shell.new
    end

    before :each do 
      # Mock the help text of the parent command
      parent_help = <<END
Tasks:
  textmate help [TASK]      # Describe available tasks or one specific task
  textmate install NAME     # Install a bundle. Source must be one of trunk, review, github, or personal. If multiple...
  textmate list [SEARCH]    # lists all the bundles installed locally
  textmate reload           # Reloads TextMate Bundles
  textmate search [SEARCH]  # Lists all the matching remote bundles
  textmate uninstall NAME   # uninstall a bundle
  textmate update           # updates all installed bundles

END
      Wrapping.should_receive(:wrap).with("help").and_return(parent_help)
    end
    
    it "returns help for the command and the parent, combined" do
      $stderr.puts "Testing help"
      $thor_runner = false
      res = capture(:stdout) { Wrapping.help(shell) }
      res.should == <<END
Tasks:
  thor bar              # Do cool stuff
  thor help [TASK]      # Describe available tasks or one specific task
  thor install NAME     # Install a bundle. Source must be one of trunk, review, github, or personal. If multiple...
  thor list [SEARCH]    # lists all the bundles installed locally
  thor reload           # Reloads TextMate Bundles
  thor search [SEARCH]  # Lists all the matching remote bundles
  thor uninstall NAME   # uninstall a bundle
  thor update           # Hijack the update command

END
    end
  end
end