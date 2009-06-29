require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'thor/core_ext/ordered_hash'

describe Thor::CoreExt::OrderedHash do
  before :each do
    @hash = Thor::CoreExt::OrderedHash.new
  end

  describe "without any items" do
    it "returns nil for an undefined key" do
      @hash["foo"].must be_nil
    end

    it "doesn't iterate through any items" do
      @hash.each { fail }
    end

    it "has an empty key and values list" do
      @hash.keys.must be_empty
      @hash.values.must be_empty
    end

    it "must be empty" do
      @hash.must be_empty
    end
  end

  describe "with several items" do
    before :each do
      @hash[:foo] = "Foo!"
      @hash[:bar] = "Bar!"
      @hash[:baz] = "Baz!"
      @hash[:bop] = "Bop!"
      @hash[:bat] = "Bat!"
    end

    it "returns nil for an undefined key" do
      @hash[:boom].must be_nil
    end

    it "returns the value for each key" do
      @hash[:foo].must == "Foo!"
      @hash[:bar].must == "Bar!"
      @hash[:baz].must == "Baz!"
      @hash[:bop].must == "Bop!"
      @hash[:bat].must == "Bat!"
    end

    it "iterates through the keys and values in order of assignment" do
      arr = []
      @hash.each do |key, value|
        arr << [key, value]
      end
      arr.must == [[:foo, "Foo!"], [:bar, "Bar!"], [:baz, "Baz!"],
                     [:bop, "Bop!"], [:bat, "Bat!"]]
    end

    it "returns the keys in order of insertion" do
      @hash.keys.must == [:foo, :bar, :baz, :bop, :bat]
    end

    it "returns the values in order of insertion" do
      @hash.values.must == ["Foo!", "Bar!", "Baz!", "Bop!", "Bat!"]
    end

    it "does not move an overwritten node to the end of the ordering" do
      @hash[:baz] = "Bip!"
      @hash.values.must == ["Foo!", "Bar!", "Bip!", "Bop!", "Bat!"]

      @hash[:foo] = "Bip!"
      @hash.values.must == ["Bip!", "Bar!", "Bip!", "Bop!", "Bat!"]

      @hash[:bat] = "Bip!"
      @hash.values.must == ["Bip!", "Bar!", "Bip!", "Bop!", "Bip!"]
    end

    it "appends another ordered hash while preserving ordering" do
      other_hash = Thor::CoreExt::OrderedHash.new
      other_hash[1] = "one"
      other_hash[2] = "two"
      other_hash[3] = "three"
      @hash.merge(other_hash).values.must == ["Foo!", "Bar!", "Baz!", "Bop!", "Bat!", "one", "two", "three"]
    end

    it "overwrites hash keys with matching appended keys" do
      other_hash = Thor::CoreExt::OrderedHash.new
      other_hash[:bar] = "bar"
      @hash.merge(other_hash)[:bar].must == "bar"
      @hash[:bar].must == "Bar!"
    end

    it "converts to an array" do
      @hash.to_a.must == [[:foo, "Foo!"], [:bar, "Bar!"], [:baz, "Baz!"], [:bop, "Bop!"], [:bat, "Bat!"]]
    end

    it "must not be empty" do
      @hash.must_not be_empty
    end

    it "deletes values from hash" do
      @hash.delete(:baz).must == "Baz!"
      @hash.values.must == ["Foo!", "Bar!", "Bop!", "Bat!"]

      @hash.delete(:foo).must == "Foo!"
      @hash.values.must == ["Bar!", "Bop!", "Bat!"]

      @hash.delete(:bat).must == "Bat!"
      @hash.values.must == ["Bar!", "Bop!"]
    end

    it "returns nil if the value to be deleted can't be found" do
      @hash.delete(:nothing).must be_nil
    end
  end
end
