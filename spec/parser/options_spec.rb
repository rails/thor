require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'thor/parser'

describe Thor::Options do
  def create(opts, defaults={})
    opts.each do |key, value|
      opts[key] = Thor::Option.parse(key, value) unless value.is_a?(Thor::Option)
    end

    @opt = Thor::Options.new(opts, defaults)
  end

  def parse(*args)
    @opt.parse(args.flatten)
  end

  def check_unknown!
    @opt.check_unknown!
  end

  describe "#to_switches" do
    it "turns true values into a flag" do
      Thor::Options.to_switches(:color => true).must == "--color"
    end

    it "ignores nil" do
      Thor::Options.to_switches(:color => nil).must == ""
    end

    it "ignores false" do
      Thor::Options.to_switches(:color => false).must == ""
    end

    it "writes --name value for anything else" do
      Thor::Options.to_switches(:format => "specdoc").must == '--format "specdoc"'
    end

    it "joins several values" do
      switches = Thor::Options.to_switches(:color => true, :foo => "bar").split(' ').sort
      switches.must == ['"bar"', "--color", "--foo"]
    end

    it "accepts arrays" do
      Thor::Options.to_switches(:count => [1,2,3]).must == "--count 1 2 3"
    end

    it "accepts hashes" do
      Thor::Options.to_switches(:count => {:a => :b}).must == "--count a:b"
    end
  end

  describe "#parse" do
    it "allows multiple aliases for a given switch" do
      create ["--foo", "--bar", "--baz"] => :string
      parse("--foo", "12")["foo"].must == "12"
      parse("--bar", "12")["foo"].must == "12"
      parse("--baz", "12")["foo"].must == "12"
    end

    it "allows custom short names" do
      create "-f" => :string
      parse("-f", "12").must == {"f" => "12"}
    end

    it "allows custom short-name aliases" do
      create ["--bar", "-f"] => :string
      parse("-f", "12").must == {"bar" => "12"}
    end

    it "accepts conjoined short switches" do
      create ["--foo", "-f"] => true, ["--bar", "-b"] => true, ["--app", "-a"] => true
      opts = parse("-fba")
      opts["foo"].must be_true
      opts["bar"].must be_true
      opts["app"].must be_true
    end

    it "accepts conjoined short switches with input" do
      create ["--foo", "-f"] => true, ["--bar", "-b"] => true, ["--app", "-a"] => :required
      opts = parse "-fba", "12"
      opts["foo"].must be_true
      opts["bar"].must be_true
      opts["app"].must == "12"
    end

    it "returns the default value if none is provided" do
      create :foo => "baz", :bar => :required
      parse("--bar", "boom")["foo"].must == "baz"
    end

    it "returns the default value from defaults hash to required arguments" do
      create Hash[:bar => :required], Hash[:bar => "baz"]
      parse["bar"].must == "baz"
    end

    it "gives higher priority to defaults given in the hash" do
      create Hash[:bar => true], Hash[:bar => false]
      parse["bar"].must == false
    end

    it "raises an error for unknown switches" do
      create :foo => "baz", :bar => :required
      parse("--bar", "baz", "--baz", "unknown")
      lambda { check_unknown! }.must raise_error(Thor::UnknownArgumentError, "Unknown switches '--baz'")
    end
    
    it "skips leading non-switches" do
      create(:foo => "baz")
      
      parse("asdf", "--foo", "bar").must == {"foo" => "bar"}
    end

    it "correctly recognizes things that look kind of like options, but aren't, as not options" do
      create(:foo => "baz")
      parse("--asdf---asdf", "baz", "--foo", "--asdf---dsf--asdf").must == {"foo" => "--asdf---dsf--asdf"}
      check_unknown!
    end

    describe "with no input" do
      it "and no switches returns an empty hash" do
        create({})
        parse.must == {}
      end

      it "and several switches returns an empty hash" do
        create "--foo" => :boolean, "--bar" => :string
        parse.must == {}
      end

      it "and a required switch raises an error" do
        create "--foo" => :required
        lambda { parse }.must raise_error(Thor::RequiredArgumentMissingError, "No value provided for required options '--foo'")
      end
    end

    describe "with one required and one optional switch" do
      before :each do
        create "--foo" => :required, "--bar" => :boolean
      end

      it "raises an error if the required switch has no argument" do
        lambda { parse("--foo") }.must raise_error(Thor::MalformattedArgumentError)
      end

      it "raises an error if the required switch isn't given" do
        lambda { parse("--bar") }.must raise_error(Thor::RequiredArgumentMissingError)
      end

      it "raises an error if the required switch is set to nil" do
        lambda { parse("--no-foo") }.must raise_error(Thor::RequiredArgumentMissingError)
      end

      it "does not raises an error if the required option has a default value" do
        create :foo => Thor::Option.new("foo", nil, true, :string, "baz"), :bar => :boolean
        lambda { parse("--bar") }.must_not raise_error
      end
    end

    describe "with :string type" do
      before(:each) do
        create ["--foo", "-f"] => :required
      end

      it "accepts a switch <value> assignment" do
        parse("--foo", "12")["foo"].must == "12"
      end

      it "accepts a switch=<value> assignment" do
        parse("-f=12")["foo"].must == "12"
        parse("--foo=12")["foo"].must == "12"
        parse("--foo=bar=baz")["foo"].must == "bar=baz"
      end

      it "accepts a --no-switch format" do
        create "--foo" => "bar"
        parse("--no-foo")["foo"].must be_nil
      end

      it "does not consume an argument for --no-switch format" do
        create "--cheese" => :string
        parse('burger', '--no-cheese', 'fries')["cheese"].must be_nil
      end

      it "accepts a --switch format on non required types" do
        create "--foo" => :string
        parse("--foo")["foo"].must == "foo"
      end
      
      it "accepts a --switch format on non required types with default values" do
        create "--baz" => :string, "--foo" => "bar"
        parse("--baz", "bang", "--foo")["foo"].must == "bar"
      end

      it "overwrites earlier values with later values" do
        parse("--foo=bar", "--foo", "12")["foo"].must == "12"
        parse("--foo", "12", "--foo", "13")["foo"].must == "13"
      end
    end

    describe "with :boolean type" do
      before(:each) do
        create "--foo" => false
      end

      it "accepts --opt assignment" do
        parse("--foo")["foo"].must == true
        parse("--foo", "--bar")["foo"].must == true
      end

      it "accepts --opt=value assignment" do
        parse("--foo=true")["foo"].must == true
        parse("--foo=false")["foo"].must == false
      end

      it "accepts --[no-]opt variant, setting false for value" do
        parse("--no-foo")["foo"].must == false
      end

      it "accepts --[skip-]opt variant, setting false for value" do
        parse("--skip-foo")["foo"].must == false
      end

      it "will prefer 'no-opt' variant over inverting 'opt' if explicitly set" do
        create "--no-foo" => true
        parse("--no-foo")["no-foo"].must == true
      end

      it "will prefer 'skip-opt' variant over inverting 'opt' if explicitly set" do
        create "--skip-foo" => true
        parse("--skip-foo")["skip-foo"].must == true
      end

      it "accepts inputs in the human name format" do
        create :foo_bar => :boolean
        parse("--foo-bar")["foo_bar"].must == true
        parse("--no-foo-bar")["foo_bar"].must == false
        parse("--skip-foo-bar")["foo_bar"].must == false
      end
    end

    describe "with :hash type" do
      before(:each) do
        create "--attributes" => :hash
      end

      it "accepts a switch=<value> assignment" do
        parse("--attributes=name:string", "age:integer")["attributes"].must == {"name" => "string", "age" => "integer"}
      end

      it "accepts a switch <value> assignment" do
        parse("--attributes", "name:string", "age:integer")["attributes"].must == {"name" => "string", "age" => "integer"}
      end

      it "must not mix values with other switches" do
        parse("--attributes", "name:string", "age:integer", "--baz", "cool")["attributes"].must == {"name" => "string", "age" => "integer"}
      end
    end

    describe "with :array type" do
      before(:each) do
        create "--attributes" => :array
      end

      it "accepts a switch=<value> assignment" do
        parse("--attributes=a", "b", "c")["attributes"].must == ["a", "b", "c"]
      end

      it "accepts a switch <value> assignment" do
        parse("--attributes", "a", "b", "c")["attributes"].must == ["a", "b", "c"]
      end

      it "must not mix values with other switches" do
        parse("--attributes", "a", "b", "c", "--baz", "cool")["attributes"].must == ["a", "b", "c"]
      end
    end

    describe "with :numeric type" do
      before(:each) do
        create "n" => :numeric, "m" => 5
      end

      it "accepts a -nXY assignment" do
        parse("-n12")["n"].must == 12
      end

      it "converts values to numeric types" do
        parse("-n", "3", "-m", ".5").must == {"n" => 3, "m" => 0.5}
      end

      it "raises error when value isn't numeric" do
        lambda { parse("-n", "foo") }.must raise_error(Thor::MalformattedArgumentError,
          "Expected numeric value for '-n'; got \"foo\"")
      end
    end

  end
end
