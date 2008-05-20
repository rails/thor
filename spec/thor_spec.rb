require File.dirname(__FILE__) + '/spec_helper'
require "thor"

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
  def foo(bar, opts)
    [bar, opts]
  end
  
  desc "bar BAZ BAT", "do some barring"
  method_options :option1 => :required
  def bar(baz, bat, opts)
    [baz, bat, opts]
  end
  
  desc "baz BAT", "do some bazzing"
  method_options :option1 => :optional
  def baz(bat, opts)
    [bat, opts]
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
  
  def method_missing(meth, *args)
    [meth, args]
  end
  
  private
  desc "what", "what"
  def what
  end
end

describe "thor" do
  it "calls a no-param method when no params are passed" do
    MyApp.start(["zoo"]).must == true
  end
  
  it "calls a single-param method when a single param is passed" do
    MyApp.start(["animal", "fish"]).must == ["fish"]
  end
  
  it "calls the alias of a method if one is provided via .map" do
    MyApp.start(["-T", "fish"]).must == ["fish"]
  end

  it "calls the alias of a method if several are provided via .map" do
    MyApp.start(["-f", "fish"]).must == ["fish", {}]
    MyApp.start(["--foo", "fish"]).must == ["fish", {}]
  end
  
  it "raises an error if a required param is not provided" do
    capture(:stderr) { MyApp.start(["animal"]) }.must =~ /`animal' was called incorrectly\. Call as `animal TYPE'/
  end
  
  it "calls a method with an optional boolean param when the param is passed" do
    MyApp.start(["foo", "one", "--force"]).must == ["one", {"force" => true, "f" => true}]
  end
  
  it "calls a method with an optional boolean param when the param is not passed" do
    MyApp.start(["foo", "one"]).must == ["one", {}]
  end
  
  it "calls a method with a required key/value param" do
    MyApp.start(["bar", "one", "two", "--option1", "hello"]).must == ["one", "two", {"option1" => "hello", "o" => "hello"}]
  end
  
  it "errors out when a required key/value option is not passed" do
    lambda { MyApp.start(["bar", "one", "two"]) }.must raise_error(Thor::Options::Error)
  end
  
  it "calls a method with an optional key/value param" do
    MyApp.start(["baz", "one", "--option1", "hello"]).must == ["one", {"option1" => "hello", "o" => "hello"}]
  end
  
  it "calls a method with an empty Hash for options if an optional key/value param is not provided" do
    MyApp.start(["baz", "one"]).must == ["one", {}]
  end
  
  it "calls method_missing if an unknown method is passed in" do
    MyApp.start(["unk", "hello"]).must == [:unk, ["hello"]]
  end
  
  it "does not call a private method no matter what" do
    lambda { MyApp.start(["what"]) }.must raise_error(NoMethodError, "the `what' task of MyApp is private")
  end
  
  it "provides useful help info for a simple method" do
    capture(:stdout) { MyApp.start(["help"]) }.must =~ /zoo +zoo around/
  end
  
  it "provides useful help info for a method with one param" do
    capture(:stdout) { MyApp.start(["help"]) }.must =~ /animal TYPE +horse around/
  end  
  
  it "provides useful help info for a method with boolean options" do
    capture(:stdout) { MyApp.start(["help"]) }.must =~ /foo BAR \[\-\-force\] +do some fooing/
  end
  
  it "provides useful help info for a method with required options" do
    capture(:stdout) { MyApp.start(["help"]) }.must =~ /bar BAZ BAT \-\-option1=OPTION1 +do some barring/
  end
  
  it "provides useful help info for a method with optional options" do
    capture(:stdout) { MyApp.start(["help"]) }.must =~ /baz BAT \[\-\-option1=OPTION1\] +do some bazzing/
  end

  it "provides useful help info for the help method itself" do
    capture(:stdout) { MyApp.start(["help"]) }.must =~ /help \[TASK\] +describe available tasks/
  end

  it "provides one line of help info per task when talking about all tasks" do
    capture(:stdout) { MyApp.start(["help"]) }.must =~ /bang FOO \[--fup\] +bangs around some/
  end

  it "provides full help info when talking about a specific task" do
    capture(:stdout) { MyApp.start(["help", "bang"]) }.must == <<END
bang FOO [--fup]
bangs around some
  This is more info!
  Everyone likes more info!
END
  end
end
