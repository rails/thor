require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require "thor/util"

describe Thor::Util do
  describe ".constant_to_thor_path" do
    it "knows how to convert class names into thor names" do
      Thor::Util.constant_to_thor_path("FooBar::BarBaz::BazBat").must == "foo_bar:bar_baz:baz_bat"
    end
    
    xit "knows how to convert a thor name to a constant" do
      Thor::Util.constant_from_thor_path("my_tasks:thor_task").must == MyTasks::ThorTask
    end
  end
  
  describe ".snake_case" do
    it "preserves no-cap strings" do
      Thor::Util.snake_case("foo").must == "foo"
      Thor::Util.snake_case("foo_bar").must == "foo_bar"
    end

    it "downcases all-caps strings" do
      Thor::Util.snake_case("FOO").must == "foo"
      Thor::Util.snake_case("FOO_BAR").must == "foo_bar"
    end

    it "downcases initial-cap strings" do
      Thor::Util.snake_case("Foo").must == "foo"
    end

    it "replaces camel-casing with underscores" do
      Thor::Util.snake_case("FooBarBaz").must == "foo_bar_baz"
      Thor::Util.snake_case("Foo_BarBaz").must == "foo_bar_baz"
    end

    it "places underscores between multiple capitals" do
      Thor::Util.snake_case("ABClass").must == "a_b_class"
    end
  end

  describe ".constant_to_thor_path" do
    it "replaces constant nesting with task namespacing" do
      Thor::Util.constant_to_thor_path("Foo::Bar::Baz").must == "foo:bar:baz"
    end

    it "snake-cases component strings" do
      Thor::Util.constant_to_thor_path("FooBar::BarBaz::BazBoom").must == "foo_bar:bar_baz:baz_boom"
    end

    it "gets rid of an initial Default module" do
      Thor::Util.constant_to_thor_path("Default::Foo::Bar").must == ":foo:bar"
      Thor::Util.constant_to_thor_path("Default").must == ""
    end

    it "accepts class and module objects" do
      require 'thor/ordered_hash'
      Thor::Util.constant_to_thor_path(Thor::OrderedHash).must == "thor:ordered_hash"
      Thor::Util.constant_to_thor_path(Thor::Util).must == "thor:util"
    end
  end

  describe ".to_constant" do
    it "returns 'Default' if no name is given" do
      Thor::Util.to_constant("").must == "Default"
    end

    it "upcases the namespaces" do
      Thor::Util.to_constant("foo").must == "Foo"
      Thor::Util.to_constant("foo:bar").must == "Foo::Bar"
    end

    it "expands task namespacing into constant nesting" do
      Thor::Util.to_constant("foo:bar:baz").must == "Foo::Bar::Baz"
    end

    it "replaces snake-casing with camel-casing" do
      Thor::Util.to_constant("foo_bar:bar_baz").must == "FooBar::BarBaz"
    end
  end

  describe ".make_constant" do
    it "returns the constant given by the string" do
      Thor::Util.make_constant("Object").must == Object
    end

    it "resolves constant nesting" do
      Thor::Util.make_constant("Thor::Util").must == Thor::Util
    end
  end

  describe ".constant_from_thor_path" do
    it "returns the named constant" do
      require 'thor/ordered_hash'
      Thor::Util.constant_from_thor_path('thor:ordered_hash').must == Thor::OrderedHash
    end
  end

  describe ".constants_in_contents" do
    it "returns an array of names of constants defined in the string" do
      list = Thor::Util.constants_in_contents("class Foo; class Bar < Thor; end; end; class Baz; class Bat; end; end")
      list.must include("Foo::Bar")
      list.must_not include("Baz::Bat")
    end

    it "doesn't put the newly-defined constants in the enclosing namespace" do
      Thor::Util.constants_in_contents("class Blat; end")
      defined?(Blat).must_not be
    end
  end
end
