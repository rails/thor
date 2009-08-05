require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module Thor::Util
  def self.clear_user_home!
    @@user_home = nil
  end
end

describe Thor::Util do
  describe "#find_by_namespace" do
    it "returns 'default' if no namespace is given" do
      Thor::Util.find_by_namespace('').must == Scripts::MyDefaults
    end

    it "adds 'default' if namespace starts with :" do
      Thor::Util.find_by_namespace(':child').must == Scripts::ChildDefault
    end

    it "returns nil if the namespace can't be found" do
      Thor::Util.find_by_namespace('thor:core_ext:ordered_hash').must be_nil
    end

    it "returns a class if it matches the namespace" do
      Thor::Util.find_by_namespace('app:broken:counter').must == BrokenCounter
    end

    it "matches classes default namespace" do
      Thor::Util.find_by_namespace('scripts:my_script').must == Scripts::MyScript
    end
  end

  describe "#namespace_from_thor_class" do
    it "replaces constant nesting with task namespacing" do
      Thor::Util.namespace_from_thor_class("Foo::Bar::Baz").must == "foo:bar:baz"
    end

    it "snake-cases component strings" do
      Thor::Util.namespace_from_thor_class("FooBar::BarBaz::BazBoom").must == "foo_bar:bar_baz:baz_boom"
    end

    it "gets rid of an initial Default module" do
      Thor::Util.namespace_from_thor_class("Default::Foo::Bar").must == ":foo:bar"
      Thor::Util.namespace_from_thor_class("Default").must == ""
    end

    it "accepts class and module objects" do
      Thor::Util.namespace_from_thor_class(Thor::CoreExt::OrderedHash).must == "thor:core_ext:ordered_hash"
      Thor::Util.namespace_from_thor_class(Thor::Util).must == "thor:util"
    end

    it "removes Thor::Sandbox namespace" do
      Thor::Util.namespace_from_thor_class("Thor::Sandbox::Package").must == "package"
    end
  end

  describe "#namespaces_in_content" do
    it "returns an array of names of constants defined in the string" do
      list = Thor::Util.namespaces_in_content("class Foo; class Bar < Thor; end; end; class Baz; class Bat; end; end")
      list.must include("foo:bar")
      list.must_not include("bar:bat")
    end

    it "doesn't put the newly-defined constants in the enclosing namespace" do
      Thor::Util.namespaces_in_content("class Blat; end")
      defined?(Blat).must_not be
      defined?(Thor::Sandbox::Blat).must be
    end
  end

  describe "#snake_case" do
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

  describe "#namespace_to_thor_class_and_task" do
    it "returns a Thor::Group class if full namespace matches" do
      Thor::Util.namespace_to_thor_class_and_task("my_counter").must == [MyCounter, nil]
    end

    it "returns a Thor class if full namespace matches" do
      Thor::Util.namespace_to_thor_class_and_task("thor").must == [Thor, nil]
    end

    it "returns a Thor class and the task name" do
      Thor::Util.namespace_to_thor_class_and_task("thor:help").must == [Thor, "help"]
    end

    it "fallbacks in the namespace:task look up even if a full namespace does not match" do
      Thor.const_set(:Help, Module.new)
      Thor::Util.namespace_to_thor_class_and_task("thor:help").must == [Thor, "help"]
      Thor.send :remove_const, :Help
    end

    describe 'errors' do
      it "raises an error if the Thor class or task can't be found" do
        lambda {
          Thor::Util.namespace_to_thor_class_and_task("foobar")
        }.must raise_error(Thor::Error, "could not find Thor class or task 'foobar'")
      end
    end
  end

  describe "#thor_classes_in" do
    it "returns thor classes inside the given class" do
      Thor::Util.thor_classes_in(MyScript).must == [MyScript::AnotherScript]
      Thor::Util.thor_classes_in(MyScript::AnotherScript).must be_empty
    end
  end

  describe "#user_home" do
    before(:each) do
      stub(ENV)[]
      Thor::Util.clear_user_home!
    end

    it "returns the user path if none variable is set on the environment" do
      Thor::Util.user_home.must == File.expand_path("~")
    end

    it "returns the *unix system path if file cannot be expanded and separator does not exist" do
      stub(File).expand_path("~"){ raise }
      previous_value = File::ALT_SEPARATOR
      capture(:stderr){ File.const_set(:ALT_SEPARATOR, false) }
      Thor::Util.user_home.must == "/"
      capture(:stderr){ File.const_set(:ALT_SEPARATOR, previous_value) }
    end

    it "returns the windows system path if file cannot be expanded and a separator exists" do
      stub(File).expand_path("~"){ raise }
      previous_value = File::ALT_SEPARATOR
      capture(:stderr){ File.const_set(:ALT_SEPARATOR, true) }
      Thor::Util.user_home.must == "C:/"
      capture(:stderr){ File.const_set(:ALT_SEPARATOR, previous_value) }
    end

    it "returns HOME/.thor if set" do
      stub(ENV)["HOME"].returns{ "/home/user/" }
      Thor::Util.user_home.must == "/home/user/"
    end

    it "returns path with HOMEDRIVE and HOMEPATH if set" do
      stub(ENV)["HOMEDRIVE"].returns{ "D:/" }
      stub(ENV)["HOMEPATH"].returns{ "Documents and Settings/James" }
      Thor::Util.user_home.must == "D:/Documents and Settings/James"
    end

    it "returns APPDATA/.thor if set" do
      stub(ENV)["APPDATA"].returns{ "/home/user/" }
      Thor::Util.user_home.must == "/home/user/"
    end
  end

  describe "#convert_constants_to_namespaces" do
    before(:each) do
      @hash = {
        :git => {
          :constants => [Object, "Thor::Sandbox::Package", Thor::CoreExt::OrderedHash]
        }
      }
    end

    it "converts constants in the hash to namespaces" do
      Thor::Util.convert_constants_to_namespaces(@hash)
      @hash[:git][:namespaces].must == [ "object", "package", "thor:core_ext:ordered_hash" ]
    end

    it "returns true if the hash changed" do
      Thor::Util.convert_constants_to_namespaces(@hash).must be_true
    end

    it "does not add namespaces to the hash if namespaces were already added" do
      Thor::Util.convert_constants_to_namespaces(@hash)
      Thor::Util.convert_constants_to_namespaces(@hash).must be_false
    end
  end
end
