require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'thor/parser'

describe Thor::Option do
  def parse(key, value)
    Thor::Option.parse(key, value)
  end

  def option(name, options={})
    @option ||= Thor::Option.new(name, options)
  end

  describe "#parse" do

    describe "with value as a symbol" do
      describe "and symbol is a valid type" do
        it "has type equals to the symbol" do
          expect(parse(:foo, :string).type).to eq(:string)
          expect(parse(:foo, :numeric).type).to eq(:numeric)
        end

        it "has not default value" do
          expect(parse(:foo, :string).default).to be_nil
          expect(parse(:foo, :numeric).default).to be_nil
        end
      end

      describe "equals to :required" do
        it "has type equals to :string" do
          expect(parse(:foo, :required).type).to eq(:string)
        end

        it "has no default value" do
          expect(parse(:foo, :required).default).to be_nil
        end
      end

      describe "and symbol is not a reserved key" do
        it "has type equals to :string" do
          expect(parse(:foo, :bar).type).to eq(:string)
        end

        it "has no default value" do
          expect(parse(:foo, :bar).default).to be_nil
        end
      end
    end

    describe "with value as hash" do
      it "has default type :hash" do
        expect(parse(:foo, :a => :b).type).to eq(:hash)
      end

      it "has default value equals to the hash" do
        expect(parse(:foo, :a => :b).default).to eq({ :a => :b })
      end
    end

    describe "with value as array" do
      it "has default type :array" do
        expect(parse(:foo, [:a, :b]).type).to eq(:array)
      end

      it "has default value equals to the array" do
        expect(parse(:foo, [:a, :b]).default).to eq([:a, :b])
      end
    end

    describe "with value as string" do
      it "has default type :string" do
        expect(parse(:foo, "bar").type).to eq(:string)
      end

      it "has default value equals to the string" do
        expect(parse(:foo, "bar").default).to eq("bar")
      end
    end

    describe "with value as numeric" do
      it "has default type :numeric" do
        expect(parse(:foo, 2.0).type).to eq(:numeric)
      end

      it "has default value equals to the numeric" do
        expect(parse(:foo, 2.0).default).to eq(2.0)
      end
    end

    describe "with value as boolean" do
      it "has default type :boolean" do
        expect(parse(:foo, true).type).to eq(:boolean)
        expect(parse(:foo, false).type).to eq(:boolean)
      end

      it "has default value equals to the boolean" do
        expect(parse(:foo, true).default).to eq(true)
        expect(parse(:foo, false).default).to eq(false)
      end
    end

    describe "with key as a symbol" do
      it "sets the name equals to the key" do
        expect(parse(:foo, true).name).to eq("foo")
      end
    end

    describe "with key as an array" do
      it "sets the first items in the array to the name" do
        expect(parse([:foo, :bar, :baz], true).name).to eq("foo")
      end

      it "sets all other items as aliases" do
        expect(parse([:foo, :bar, :baz], true).aliases).to eq([:bar, :baz])
      end
    end
  end

  it "returns the switch name" do
    expect(option("foo").switch_name).to eq("--foo")
    expect(option("--foo").switch_name).to eq("--foo")
  end

  it "returns the human name" do
    expect(option("foo").human_name).to eq("foo")
    expect(option("--foo").human_name).to eq("foo")
  end

  it "converts underscores to dashes" do
    expect(option("foo_bar").switch_name).to eq("--foo-bar")
  end

  it "can be required and have default values" do
    option = option("foo", :required => true, :type => :string, :default => "bar")
    expect(option.default).to eq("bar")
    expect(option).to be_required
  end

  it "cannot be required and have type boolean" do
    expect {
      option("foo", :required => true, :type => :boolean)
    }.to raise_error(ArgumentError, "An option cannot be boolean and required.")
  end

  it "allows type predicates" do
    expect(parse(:foo, :string)).to be_string
    expect(parse(:foo, :boolean)).to be_boolean
    expect(parse(:foo, :numeric)).to be_numeric
  end

  it "raises an error on method missing" do
    expect {
      parse(:foo, :string).unknown?
    }.to raise_error(NoMethodError)
  end

  describe "#usage" do

    it "returns usage for string types" do
      expect(parse(:foo, :string).usage).to eq("[--foo=FOO]")
    end

    it "returns usage for numeric types" do
      expect(parse(:foo, :numeric).usage).to eq("[--foo=N]")
    end

    it "returns usage for array types" do
      expect(parse(:foo, :array).usage).to eq("[--foo=one two three]")
    end

    it "returns usage for hash types" do
      expect(parse(:foo, :hash).usage).to eq("[--foo=key:value]")
    end

    it "returns usage for boolean types" do
      expect(parse(:foo, :boolean).usage).to eq("[--foo]")
    end

    it "uses padding when no aliases is given" do
      expect(parse(:foo, :boolean).usage(4)).to eq("    [--foo]")
    end

    it "uses banner when supplied" do
      expect(option(:foo, :required => false, :type => :string, :banner => "BAR").usage).to eq("[--foo=BAR]")
    end

    it "checkes when banner is an empty string" do
      expect(option(:foo, :required => false, :type => :string, :banner => "").usage).to eq("[--foo]")
    end

    describe "with required values" do
      it "does not show the usage between brackets" do
        expect(parse(:foo, :required).usage).to eq("--foo=FOO")
      end
    end

    describe "with aliases" do
      it "does not show the usage between brackets" do
        expect(parse([:foo, "-f", "-b"], :required).usage).to eq("-f, -b, --foo=FOO")
      end
    end
  end
end
