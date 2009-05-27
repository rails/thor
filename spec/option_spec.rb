require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'thor/option'

describe Thor::Option do
  def parse(key, value)
    Thor::Option.parse(key, value)
  end

  def option(name, description=nil, required=false, type=:default, default=nil, aliases=[])
    @option ||= Thor::Option.new(name, description, required, type, default, aliases)
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

      describe "equals to :optional" do
        it "has type equals to :default" do
          parse(:foo, :optional).type.must == :default
        end

        it "has no default value" do
          parse(:foo, :optional).default.must be_nil
        end
      end

      describe "and symbol is not a reserved key" do
        it "has type equals to :default" do
          parse(:foo, :bar).type.must == :default
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

  it "can be required" do
    parse(:foo, :required).must be_required
    parse(:foo, :required).must_not be_optional
  end

  it "can be optional" do
    parse(:foo, :optional).must_not be_required
    parse(:foo, :optional).must be_optional
  end

  it "can't be boolean and required" do
    option(:task, nil, true, :boolean).must_not be_required
    option(:task, nil, true, :boolean).must be_optional
  end

  it "can't be required and have a default value" do
    option(:task, nil, true, :string, "bla").must be_required
    option(:task, nil, true, :string, "bla").default.must be_nil
  end

  it "requires an argument when type is a string, array, hash or numeric" do
    [:string, :array, :hash, :numeric].each do |type|
      parse(:foo, type).argument_required?.must be_true
    end
  end

  it "does not require an argument when type is default or boolean" do
    [:default, :boolean].each do |type|
      parse(:foo, type).argument_required?.must be_false
    end
  end

  it "raises an error if name is not supplied" do
    lambda {
      option(nil)
    }.must raise_error(ArgumentError, "Option name can't be nil.")
  end

  it "returns the switch name" do
    option("foo").switch_name.must == "--foo"
    option("--foo").switch_name.must == "--foo"
  end

  it "returns the human name" do
    option("foo").human_name.must == "foo"
    option("--foo").human_name.must == "foo"
  end

  describe "#formatted_default" do
    describe "and default is nil" do
      it "must be nil" do
        parse(:foo, :bar).formatted_default.must be_nil
      end
    end

    describe "when type is a string" do
      it "returns the string" do
        parse(:foo, "bar").formatted_default.must == "bar"
      end
    end

    describe "when type is a numeric" do
      it "returns the value as string" do
        parse(:foo, 2.0).formatted_default.must == "2.0"
      end
    end

    describe "when type is an array" do
      it "returns the inspected array" do
        parse(:foo, [1,2,3]).formatted_default.must == "[1, 2, 3]"
      end
    end

    describe "when type is a hash" do
      it "returns the hash as key:value" do
        value = parse(:foo, { :a => :b, :c => :d }).formatted_default
        value.split(" ").sort.join(" ").must == "a:b c:d"
      end
    end

    describe "when type is a boolean" do
      it "returns nil" do
        parse(:foo, true).formatted_default.must be_nil
      end
    end
  end

  describe "#formatted_value" do
    describe "when type is a string" do
      it "returns the human name upcased" do
        parse(:foo, :string).formatted_value.must == "FOO"
      end
    end

    describe "when type is a numeric" do
      it "returns N" do
        parse(:foo, :numeric).formatted_value.must == "N"
      end
    end

    describe "when type is an array" do
      it "returns a generic array" do
        parse(:foo, :array).formatted_value.must == "[a,b,3]"
      end
    end

    describe "when type is a hash" do
      it "returns a key:value sample" do
        parse(:foo, :hash).formatted_value.must == "key:value"
      end
    end

    describe "when type is a boolean" do
      it "returns nil" do
        parse(:foo, :boolean).formatted_value.must be_nil
      end
    end
  end
end
