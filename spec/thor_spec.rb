require File.dirname(__FILE__) + '/spec_helper'
require "thor"

class MyApp < Thor
  
  map "-T" => :animal
  
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
    ARGV.replace ["zoo"]
    MyApp.start.must == true
  end
  
  it "calls a single-param method when a single param is passed" do
    ARGV.replace ["animal", "fish"]
    MyApp.start.must == ["fish"]
  end
  
  it "calls the alias of a method if one is provided via .map" do
    ARGV.replace ["-T", "fish"]
    MyApp.start.must == ["fish"]
  end
  
  it "raises an error if a required param is not provided" do
    ARGV.replace ["animal"]
    lambda { MyApp.start }.must raise_error(ArgumentError)
  end
  
  it "calls a method with an optional boolean param when the param is passed" do
    ARGV.replace ["foo", "one", "--force"]
    MyApp.start.must == ["one", {"force" => true, "f" => true}]
  end
  
  it "calls a method with an optional boolean param when the param is not passed" do
    ARGV.replace ["foo", "one"]
    MyApp.start.must == ["one", {}]
  end
  
  it "calls a method with a required key/value param" do
    ARGV.replace ["bar", "one", "two", "--option1", "hello"]
    MyApp.start.must == ["one", "two", {"option1" => "hello", "o" => "hello"}]
  end
  
  it "errors out when a required key/value option is not passed" do
    ARGV.replace ["bar", "one", "two"]
    lambda { MyApp.start }.must raise_error(Getopt::Long::Error)
  end
  
  it "calls a method with an optional key/value param" do
    ARGV.replace ["baz", "one", "--option1", "hello"]
    MyApp.start.must == ["one", {"option1" => "hello", "o" => "hello"}]
  end
  
  it "calls a method with an empty Hash for options if an optional key/value param is not provided" do
    ARGV.replace ["baz", "one"]
    MyApp.start.must == ["one", {}]
  end
  
  it "calls method_missing if an unknown method is passed in" do
    ARGV.replace ["unk", "hello"]
    MyApp.start.must == [:unk, ["hello"]]
  end
  
  it "does not call a private method no matter what" do
    ARGV.replace ["what"]
    MyApp.start.must == nil
  end
  
  it "provides useful help info for a simple method" do
    StdOutCapturer.call_func { ARGV.replace ["help"]; MyApp.start }.must =~ /zoo +zoo around/
  end
  
  it "provides useful help info for a method with one param" do
    StdOutCapturer.call_func { ARGV.replace ["help"]; MyApp.start }.must =~ /animal TYPE +horse around/
  end  
  
  it "provides useful help info for a method with boolean options" do
    StdOutCapturer.call_func { ARGV.replace ["help"]; MyApp.start }.must =~ /foo BAR \[\-\-force\] +do some fooing/
  end
  
  it "provides useful help info for a method with required options" do
    StdOutCapturer.call_func { ARGV.replace ["help"]; MyApp.start }.must =~ /bar BAZ BAT \-\-option1=OPTION1 +do some barring/
  end
  
  it "provides useful help info for a method with optional options" do
    StdOutCapturer.call_func { ARGV.replace ["help"]; MyApp.start }.must =~ /baz BAT \[\-\-option1=OPTION1\] +do some bazzing/
  end    
end