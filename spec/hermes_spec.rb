require File.dirname(__FILE__) + '/spec_helper'
require "hermes"

class MyApp
  extend Hermes
  
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
end

describe "hermes" do
  it "calls a no-param method when no params are passed" do
    ARGV.replace ["zoo"]
    MyApp.start.should == true
  end
  
  it "calls a single-param method when a single param is passed" do
    ARGV.replace ["animal", "fish"]
    MyApp.start.should == ["fish"]
  end
  
  it "calls the alias of a method if one is provided via .map" do
    ARGV.replace ["-T", "fish"]
    MyApp.start.should == ["fish"]
  end
  
  it "raises an error if a required param is not provided" do
    ARGV.replace ["animal"]
    lambda { MyApp.start }.should raise_error(ArgumentError)
  end
  
  it "calls a method with an optional boolean param when the param is passed" do
    ARGV.replace ["foo", "one", "--force"]
    MyApp.start.should == ["one", {"force" => true, "f" => true}]
  end
  
  it "calls a method with an optional boolean param when the param is not passed" do
    ARGV.replace ["foo", "one"]
    MyApp.start.should == ["one", {}]
  end
  
  it "calls a method with a required key/value param" do
    ARGV.replace ["bar", "one", "two", "--option1", "hello"]
    MyApp.start.should == ["one", "two", {"option1" => "hello", "o" => "hello"}]
  end
  
  it "errors out when a required key/value option is not passed" do
    ARGV.replace ["bar", "one", "two"]
    lambda { MyApp.start }.should raise_error(Getopt::Long::Error)
  end
  
  it "calls a method with an optional key/value param" do
    ARGV.replace ["baz", "one", "--option1", "hello"]
    MyApp.start.should == ["one", {"option1" => "hello", "o" => "hello"}]
  end
  
  it "calls a method with an empty Hash for options if an optional key/value param is not provided" do
    ARGV.replace ["baz", "one"]
    MyApp.start.should == ["one", {}]    
  end
end