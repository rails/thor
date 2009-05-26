require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

class MyScript < Thor
  group :script
  default_task :example_default_task

  map "-T" => :animal, ["-f", "--foo"] => :foo

  desc "zoo", "zoo around"
  def zoo
    true
  end

  desc "animal TYPE", "horse around"
  def animal(type)
    [type]
  end

  desc "foo BAR", <<END
do some fooing
  This is more info!
  Everyone likes more info!
END
  method_options :force => :boolean
  def foo(bar)
    [bar, options]
  end

  desc "example_default_task", "example!"
  def example_default_task
    "default task"
  end

  desc "bar BAZ BAT", "do some barring"
  method_options :option1 => :required
  def bar(baz, bat)
    [baz, bat, options]
  end

  desc "baz BAT", "do some bazzing"
  method_options :option1 => :optional
  def baz(bat)
    [bat, options]
  end

  desc "call_myself_with_wrong_arity", "get the right error"
  def call_myself_with_wrong_arity
    call_myself_with_wrong_arity(4)
  end

  def method_missing(meth, *args)
    [meth, args]
  end

  private

    desc "what", "what"
    def what
    end
end

class MyChildScript < MyScript
  method_options :force => :boolean, :param => :numeric
  def initialize(*args)
    super
  end

  desc "zoo", "zoo around"
  method_options :param => :required
  def zoo
    options
  end

  desc "animal TYPE", "horse around"
  method_options :other => :optional
  def animal(type)
    [type, options]
  end
end

module Scripts
  class MyGrandChildScript < MyChildScript
    default_options :force => :optional, :param => :required
  end
end

class Amazing
  desc "hello", "say hello"
  def hello
    puts "Hello"
  end
end

describe Thor::Base do
  describe "#default_task" do
    it "sets a default task" do
      MyScript.default_task.must == "example_default_task"
    end

    it "invokes the default task if no command is specified" do
      MyScript.start([]).must == "default task"
    end

    it "inherits the default task from parent" do
      MyChildScript.default_task.must == "example_default_task"
    end
  end

  describe "#map" do
    it "calls the alias of a method if one is provided" do
      MyScript.start(["-T", "fish"]).must == ["fish"]
    end

    it "calls the alias of a method if several are provided via .map" do
      MyScript.start(["-f", "fish"]).must == ["fish", {}]
      MyScript.start(["--foo", "fish"]).must == ["fish", {}]
    end

    it "inherits all mappings from parent" do
      MyChildScript.default_task.must == "example_default_task"
    end
  end

  describe "#desc" do
    before(:all) do
      @content = capture(:stdout) { MyScript.start(["help"]) }
    end

    it "provides useful help info for the help method itself" do
      @content.must =~ /help \[TASK\] +describe available tasks/
    end

    it "provides useful help info for a simple method" do
      @content.must =~ /zoo +zoo around/
    end

    it "provides useful help info for a method with params" do
      @content.must =~ /animal TYPE +horse around/
    end

    it "provides useful help info for a method with options" do
      @content.must =~ /foo BAR \[\-\-force\] +do some fooing/
    end

    it "provides full help info when talking about a specific task" do
      capture(:stdout) { MyScript.start(["help", "foo"]) }.must == <<END
foo BAR [--force]
do some fooing
  This is more info!
  Everyone likes more info!
END
    end
  end

  describe "#group" do
    it "sets a group name" do
      MyScript.group_name.must == "script"
    end

    it "inherits the group name from parent" do
      MyChildScript.group_name.must == "script"
    end

    it "defaults to standard if no group name is given" do
      Amazing.group_name.must == "standard"
    end
  end

  describe "#method_options" do
    it "sets default options if called before an initializer" do
      options = MyChildScript.default_options
      options[:force].type.must == :boolean
      options[:param].type.must == :numeric
    end

    it "overwrites default options if called on the method scope" do
      args = ["zoo", "--force", "--param", "feathers"]
      options = MyChildScript.start(args)
      options.must == { "force" => true, "param" => "feathers" }
    end

    it "allows default options to be merged with method options" do
      args = ["animal", "bird", "--force", "--param", "1.0", "--other", "tweets"]
      arg, options = MyChildScript.start(args)
      arg.must == 'bird'
      options.must == { "force"=>true, "param"=>1.0, "other"=>"tweets" }
    end
  end

  describe "#default_options" do
    it "sets default options overwriting superclass definitions" do
      options = Scripts::MyGrandChildScript.default_options
      options[:force].must be_optional
      options[:param].must be_required
    end
  end

  describe "#subclasses" do
    it "tracks its subclasses in an Array" do
      Thor.subclasses.must include(MyScript)
      Thor.subclasses.must include(MyChildScript)
      Thor.subclasses.must include(Scripts::MyGrandChildScript)

      MyChildScript.subclasses.must include(Scripts::MyGrandChildScript)
      MyChildScript.subclasses.must_not include(MyScript)
    end
  end

  describe "#subclass_files" do
    it "returns tracked subclasses, grouped by the files they come from" do
      Thor.subclass_files[File.expand_path(__FILE__)].must == [ MyScript, MyChildScript, Scripts::MyGrandChildScript, Amazing ]
    end

    it "tracks a single subclass across multiple files" do
      thorfile = File.join(File.dirname(__FILE__), "fixtures", "task.thor")
      Thor.subclass_files[File.expand_path(thorfile)].must include(Amazing)
      Thor.subclass_files[File.expand_path(__FILE__)].must include(Amazing)
    end
  end

  describe "#[]" do
    it "retrieves an specific task object" do
      MyScript[:foo].class.must == Thor::Task
      MyChildScript[:foo].class.must == Thor::Task
      Scripts::MyGrandChildScript[:foo].class.must == Thor::Task
    end

    it "returns a dynamic task to allow method missing invocation" do
      MyScript[:none].class.must == Thor::Task
      MyScript[:none].description =~ /dynamic/
    end
  end

  describe "#start" do
    it "calls a no-param method when no params are passed" do
      MyScript.start(["zoo"]).must == true
    end
    
    it "calls a single-param method when a single param is passed" do
      MyScript.start(["animal", "fish"]).must == ["fish"]
    end
    
    xit "raises an error if a required param is not provided" do
      capture(:stderr) { MyScript.start(["animal"]) }.must =~ /`animal' was called incorrectly\. Call as `animal TYPE'/
    end
    
    it "calls a method with an optional boolean param when the param is passed" do
      MyScript.start(["foo", "one", "--force"]).must == ["one", {"force" => true}]
    end
    
    it "calls a method with an optional boolean param when the param is not passed" do
      MyScript.start(["foo", "one"]).must == ["one", {}]
    end
    
    it "calls a method with a required key/value param" do
      MyScript.start(["bar", "one", "two", "--option1", "hello"]).must == ["one", "two", {"option1" => "hello"}]
    end
    
    it "calls a method with an optional key/value param" do
      MyScript.start(["baz", "one", "--option1", "hello"]).must == ["one", {"option1" => "hello"}]
    end

    it "allows options at the beginning and end of the arguments" do
      MyScript.start(["baz", "--option1", "hello", "one"]).must == ["one", {"option1" => "hello"}]
    end
    
    it "calls a method with an empty Hash for options if an optional key/value param is not provided" do
      MyScript.start(["baz", "one"]).must == ["one", {}]
    end
    
    it "calls method_missing if an unknown method is passed in" do
      MyScript.start(["unk", "hello"]).must == [:unk, ["hello"]]
    end

    xit "does not call a private method no matter what" do
      lambda { MyScript.start(["what"]) }.must raise_error(NoMethodError, "the `what' task of MyApp is private")
    end

    it "raises when an exception happens within the task call" do
      lambda { MyScript.start(["call_myself_with_wrong_arity"]) }.must raise_error
    end
  end

  describe "#invoke" do
    it "invokes the named command regardless of the command line options with invoke()" do
      MyScript.invoke(:animal, ["fish"]).must == ["fish"]
    end
  end

  describe "#maxima" do
    it "returns the maximum length for usage, description and options" do
      MyScript.maxima.description.must == 64
      MyScript.maxima.usage.must       == 28
      MyScript.maxima.options.must     == 19
    end
  end
end
