require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

class MyApp < Thor
  
  map "-T" => :animal, ["-f", "--foo"] => :foo

  desc "zoo", "zoo around"
  def zoo
    true
  end

  desc "animal TYPE", "horse around"
  def animal(type)
    [type]
  end

  desc "foo BAR", "do some fooing"
  method_options :force => :boolean
  def foo(bar)
    [bar, options]
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

  desc "bang FOO", <<END
bangs around some
  This is more info!
  Everyone likes more info!
END
  method_options :fup => :boolean
  def bang(foo)
    "bang"
  end
  
  desc "call_myself_with_wrong_arity", "get the right error"
  def call_myself_with_wrong_arity
    call_myself_with_wrong_arity(4)
  end
  
  default_task :example_default_task
  
  desc "example_default_task", "example!"
  def example_default_task
    "default task"
  end
  
  
  def method_missing(meth, *args)
    [meth, args]
  end
  
  private
  desc "what", "what"
  def what
  end
end

class GlobalOptionsTasks < Thor

  method_options :force => :boolean, :param => :numeric
  def initialize(*args)
    super
  end
  
  desc "animal TYPE", "horse around"
  method_options :other => :optional
  def animal(type)
    [type, options]
  end
  
  desc "zoo", "zoo around"
  method_options :param => :required
  def zoo
    options
  end
end

class ChildGlobalOptionsTasks < GlobalOptionsTasks
  default_options :force => :optional, :param => :required
end

describe "thor" do
  it "calls a no-param method when no params are passed" do
    MyApp.start(["zoo"]).must == true
  end
  
  it "calls a single-param method when a single param is passed" do
    MyApp.start(["animal", "fish"]).must == ["fish"]
  end
  
  xit "raises an error if a required param is not provided" do
    capture(:stderr) { MyApp.start(["animal"]) }.must =~ /`animal' was called incorrectly\. Call as `animal TYPE'/
  end
  
  it "calls a method with an optional boolean param when the param is passed" do
    MyApp.start(["foo", "one", "--force"]).must == ["one", {"force" => true}]
  end
  
  it "calls a method with an optional boolean param when the param is not passed" do
    MyApp.start(["foo", "one"]).must == ["one", {}]
  end
  
  it "calls a method with a required key/value param" do
    MyApp.start(["bar", "one", "two", "--option1", "hello"]).must == ["one", "two", {"option1" => "hello"}]
  end
  
  it "calls a method with an optional key/value param" do
    MyApp.start(["baz", "one", "--option1", "hello"]).must == ["one", {"option1" => "hello"}]
  end

  it "allows options at the beginning and end of the arguments" do
    MyApp.start(["baz", "--option1", "hello", "one"]).must == ["one", {"option1" => "hello"}]
  end
  
  it "calls a method with an empty Hash for options if an optional key/value param is not provided" do
    MyApp.start(["baz", "one"]).must == ["one", {}]
  end
  
  it "calls method_missing if an unknown method is passed in" do
    MyApp.start(["unk", "hello"]).must == [:unk, ["hello"]]
  end

  xit "does not call a private method no matter what" do
    lambda { MyApp.start(["what"]) }.must raise_error(NoMethodError, "the `what' task of MyApp is private")
  end

  it "raises when an exception happens within the task call" do
    lambda { MyApp.start(["call_myself_with_wrong_arity"]) }.must raise_error
  end
  
  it "invokes the named command regardless of the command line options with invoke()" do
    MyApp.invoke(:baz, ["one"]).must == ["one", {}]
  end
end
