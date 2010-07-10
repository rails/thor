require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'thor/parser'

describe Thor::Option do
  def parse(key, value)
    Thor::Option.parse(key, value)
  end

  def option(name, *args)
    @option ||= Thor::Option.new(name, *args)
  end

  describe "#parse" do

    describe "with value as a symbol" do
      describe "and symbol is a valid type" do
        it "has type equals to the symbol" do
          parse(:foo, :string).type.must == :string
          parse(:foo, :numeric).type.must == :numeric
        end

        it "has not default value" do
          parse(:foo, :string).default.must be_nil
          parse(:foo, :numeric).default.must be_nil
        end
      end

      describe "equals to :required" do
        it "has type equals to :string" do
          parse(:foo, :required).type.must == :string
        end

        it "has no default value" do
          parse(:foo, :required).default.must be_nil
        end
      end

      describe "and symbol is not a reserved key" do
        it "has type equals to :string" do
          parse(:foo, :bar).type.must == :string
        end

        it "has no default value" do
          parse(:foo, :bar).default.must be_nil
        end
      end
    end

    describe "with value as hash" do
      it "has default type :hash" do
        parse(:foo, :a => :b).type.must == :hash
      end

      it "has default value equals to the hash" do
        parse(:foo, :a => :b).default.must == { :a => :b }
      end
    end

    describe "with value as array" do
      it "has default type :array" do
        parse(:foo, [:a, :b]).type.must == :array
      end

      it "has default value equals to the array" do
        parse(:foo, [:a, :b]).default.must == [:a, :b]
      end
    end

    describe "with value as string" do
      it "has default type :string" do
        parse(:foo, "bar").type.must == :string
      end

      it "has default value equals to the string" do
        parse(:foo, "bar").default.must == "bar"
      end
    end

    describe "with value as numeric" do
      it "has default type :numeric" do
        parse(:foo, 2.0).type.must == :numeric
      end

      it "has default value equals to the numeric" do
        parse(:foo, 2.0).default.must == 2.0
      end
    end

    describe "with value as boolean" do
      it "has default type :boolean" do
        parse(:foo, true).type.must == :boolean
        parse(:foo, false).type.must == :boolean
      end

      it "has default value equals to the boolean" do
        parse(:foo, true).default.must == true
        parse(:foo, false).default.must == false
      end
    end

    describe "with key as a symbol" do
      it "sets the name equals to the key" do
        parse(:foo, true).name.must == "foo"
      end
    end

    describe "with key as an array" do
      it "sets the first items in the array to the name" do
        parse([:foo, :bar, :baz], true).name.must == "foo"
      end

      it "sets all other items as aliases" do
        parse([:foo, :bar, :baz], true).aliases.must == [:bar, :baz]
      end
    end
  end

  it "returns the switch name" do
    option("foo").switch_name.must == "--foo"
    option("--foo").switch_name.must == "--foo"
  end

  it "returns the human name" do
    option("foo").human_name.must == "foo"
    option("--foo").human_name.must == "foo"
  end

  it "converts underscores to dashes" do
    option("foo_bar").switch_name.must == "--foo-bar"
  end

  it "can be required and have default values" do
    option = option("foo", nil, true, :string, "bar")
    option.default.must == "bar"
    option.must be_required
  end

  it "cannot be required and have type boolean" do
    lambda {
      option("foo", nil, true, :boolean)
    }.must raise_error(ArgumentError, "An option cannot be boolean and required.")
  end

  it "allows type predicates" do
    parse(:foo, :string).must be_string
    parse(:foo, :boolean).must be_boolean
    parse(:foo, :numeric).must be_numeric
  end

  it "raises an error on method missing" do
    lambda {
      parse(:foo, :string).unknown?
    }.must raise_error(NoMethodError)
  end

  describe "#usage" do

    it "returns usage for string types" do
      parse(:foo, :string).usage.must == "[--foo=FOO]"
    end

    it "returns usage for numeric types" do
      parse(:foo, :numeric).usage.must == "[--foo=N]"
    end

    it "returns usage for array types" do
      parse(:foo, :array).usage.must == "[--foo=one two three]"
    end

    it "returns usage for hash types" do
      parse(:foo, :hash).usage.must == "[--foo=key:value]"
    end

    it "returns usage for boolean types" do
      parse(:foo, :boolean).usage.must == "[--foo]"
    end

    it "uses padding when no aliases is given" do
      parse(:foo, :boolean).usage(4).must == "    [--foo]"
    end

    it "uses banner when supplied" do
      option(:foo, nil, false, :string, nil, "BAR").usage.must == "[--foo=BAR]"
    end

    it "checkes when banner is an empty string" do
      option(:foo, nil, false, :string, nil, "").usage.must == "[--foo]"
    end

    describe "with required values" do
      it "does not show the usage between brackets" do
        parse(:foo, :required).usage.must == "--foo=FOO"
      end
    end

    describe "with aliases" do
      it "does not show the usage between brackets" do
        parse([:foo, "-f", "-b"], :required).usage.must == "-f, -b, --foo=FOO"
      end
    end
  end
end
