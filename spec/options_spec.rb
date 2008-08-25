require File.dirname(__FILE__) + '/spec_helper'
require "thor/options"

describe Thor::Options do
  it "automatically aliases long switches with their first letter" do
    Thor::Options.new(["--foo"], {"--foo" => true}).getopts["f"].must be_true
    Thor::Options.new(["-f"], {"--foo" => true}).getopts["foo"].must be_true
  end

  it "doesn't alias switches that have multiple names given" do
    Thor::Options.new(["--foo"], {["--foo", "--bar"] => true}).getopts["f"].must_not be
    Thor::Options.new(["-f"], {["--foo", "--bar"] => true}).getopts["foo"].must_not be
  end

  it "allows multiple aliases for a given switch" do
    Thor::Options.new(["--bar", "12"], {["--foo", "--bar", "--baz"] => :optional}).getopts.must ==
      {"foo" => "12", "bar" => "12", "baz" => "12", :foo => "12", :bar => "12", :baz => "12"}
  end

  it "allows custom short names" do
    Thor::Options.new(["-f", "12"], {"-f" => :optional}).getopts.must == {"f" => "12", :f => "12"}
  end

  it "allows custom short-name aliases" do
    Thor::Options.new(["-f", "12"], {["--bar", "-f"] => :optional}).getopts.must ==
      {"bar" => "12", "f" => "12", :bar => "12", :f => "12"}
  end

  it "accepts =-format switch assignment" do
    Thor::Options.new(["--foo=12"], {"--foo" => :required}).getopts["foo"].must == "12"
  end

  it "accepts conjoined short switches" do
    opts = Thor::Options.new(["-fba"], {"--foo" => true, "--bar" => true, "--app" => true}).getopts
    opts["foo"].must be_true
    opts["bar"].must be_true
    opts["app"].must be_true
  end

  it "accepts conjoined short switches with arguments" do
    opts = Thor::Options.new(["-fba", "12"], {"--foo" => true, "--bar" => true, "--app" => :required}).getopts
    opts["foo"].must be_true
    opts["bar"].must be_true
    opts["app"].must == "12"
  end

  it "makes hash keys available as symbols as well" do
    opts = Thor::Options.new(["--foo", "12"], "--foo" => :optional).getopts
    opts[:foo].must == "12"
    opts[:f].must == "12"
  end

  describe " with no arguments" do
    describe " and no switches" do
      before :each do
        @options = Thor::Options.new([], {})
      end

      it "returns an empty array for #skip_non_opts" do
        @options.skip_non_opts.must == []
      end

      it "returns an empty hash for #getopts" do
        @options.getopts.must == {}
      end
    end

    describe " and several switches" do
      before :each do
        @options = Thor::Options.new([], {"--foo" => true, "--bar" => :optional})
      end

      it "returns an empty array for #skip_non_opts" do
        @options.skip_non_opts.must == []
      end

      it "returns an empty hash for #getopts" do
        @options.getopts.must == {}
      end
    end

    describe " and a required switch" do
      before :each do
        @options = Thor::Options.new([], {"--foo" => :required})
      end

      it "raises an error for #getopts" do
        lambda { @options.getopts }.must raise_error(Thor::Options::Error, "no value provided for required argument '--foo'")
      end
    end
  end

  describe " with several boolean switches" do
    before :each do
      @switches = {"--foo" => true, "--bar" => :boolean}
    end

    it "sets existant switches to true" do
      Thor::Options.new(["--foo"], @switches).getopts["foo"].must be_true
      Thor::Options.new(["--bar"], @switches).getopts["bar"].must be_true
      opts = Thor::Options.new(["--foo", "--bar"], @switches).getopts
      opts["foo"].must be_true
      opts["bar"].must be_true
    end

    it "doesn't set nonexistant switches" do
      Thor::Options.new(["--foo"], @switches).getopts["bar"].must_not be
      Thor::Options.new(["--bar"], @switches).getopts["foo"].must_not be
      opts = Thor::Options.new([], @switches).getopts
      opts["foo"].must_not be
      opts["bar"].must_not be
    end
  end

  describe " with several optional switches" do
    before :each do
      @switches = {"--foo" => :optional, "--bar" => :optional}
    end

    it "sets switches without arguments to true" do
      Thor::Options.new(["--foo"], @switches).getopts["foo"].must be_true
      Thor::Options.new(["--bar"], @switches).getopts["bar"].must be_true
    end

    it "doesn't set nonexistant switches" do
      Thor::Options.new(["--foo"], @switches).getopts["bar"].must_not be
      Thor::Options.new(["--bar"], @switches).getopts["foo"].must_not be
    end

    it "sets switches with arguments to their arguments" do
      Thor::Options.new(["--foo", "12"], @switches).getopts["foo"].must == "12"
      Thor::Options.new(["--bar", "12"], @switches).getopts["bar"].must == "12"
    end

    it "assumes something that could be either a switch or an argument is a switch" do
      Thor::Options.new(["--foo", "--bar"], @switches).getopts["foo"].must be_true
    end

    it "overwrites earlier values with later values" do
      Thor::Options.new(["--foo", "--foo", "12"], @switches).getopts["foo"].must == "12"
      Thor::Options.new(["--foo", "12", "--foo", "13"], @switches).getopts["foo"].must == "13"
    end
  end

  describe " with one required and one optional switch" do
    before :each do
      @switches = {"--foo" => :required, "--bar" => :optional}
    end

    it "raises an error if the required switch has no argument" do
      lambda { Thor::Options.new(["--foo"], @switches).getopts }.must raise_error(Thor::Options::Error, "no value provided for required argument '--foo'")
    end

    it "raises an error if the required switch isn't given" do
      lambda { Thor::Options.new(["--bar"], @switches).getopts }.must raise_error(Thor::Options::Error, "no value provided for required argument '--foo'")
    end

    it "raises an error if a switch name is given as the argument to the required switch" do
      lambda { Thor::Options.new(["--foo", "--bar"], @switches).getopts }.must raise_error(Thor::Options::Error, "cannot pass switch '--bar' as an argument")
    end

    it "sets the required switch to its argument" do
      Thor::Options.new(["--foo", "12"], @switches).getopts["foo"].must == "12"
    end

    it "overwrites earlier values with later values" do
      Thor::Options.new(["--foo", "12", "--foo", "13"], @switches).getopts["foo"].must == "13"
    end
  end

  describe " with several non-switch arguments" do
    before :each do
      @options = Thor::Options.new(["foo", "bar", "--baz", "--foo", "12", "--bar", "-T", "bang"],
                                   "--foo" => :required, "--bar" => true)
    end

    it "returns the initial non-option arguments for #skip_non_opts" do
      @options.skip_non_opts.must == ["foo", "bar", "--baz"]
    end

    it "parses the options for #getopts after #skip_non_opts" do
      @options.skip_non_opts
      @options.getopts.must == {
        "foo" => "12", "f" => "12", "bar" => true, "b" => true,
        :foo => "12", :f => "12", :bar => true, :b => true,
      }
    end

    it "returns the remaining non-option arguments for #args after #skip_non_opts and #getopts" do
      @options.skip_non_opts
      @options.getopts
      @options.args == ["-T", "bang"]
    end
  end
  
  it "allows optional arguments with default values" do
    @options = Thor::Options.new(["--branch", "bugfix"], "--branch" => "master")
    @options.getopts.must == { "branch" => "bugfix", :branch => "bugfix", "b" => "bugfix", :b => "bugfix" }
  end
  
  it "allows optional arguments with default values" do
    @options = Thor::Options.new([], "--branch" => "master")
    @options.getopts.must == { "branch" => "master", :branch => "master", "b" => "master", :b => "master" }
  end
end
