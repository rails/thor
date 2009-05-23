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

    it "has an empty values list" do
      @hash.values.must be_empty
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

    it "shouldn't be the same as its clone" do
      new_hash = @hash.clone
      new_hash[:bang] = "Bang!"
      @hash[:bang].must be_nil
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

    it "returns the values in order of insertion" do
      @hash.values.must == ["Foo!", "Bar!", "Baz!", "Bop!", "Bat!"]
    end

    it "should move an overwritten node to the end of the ordering" do
      @hash[:bar] = "Bip!"
      @hash.values.must == ["Foo!", "Baz!", "Bop!", "Bat!", "Bip!"]
    end

    it "should append another ordered hash while preserving ordering" do
      other_hash = Thor::CoreExt::OrderedHash.new
      other_hash[1] = "one"
      other_hash[2] = "two"
      other_hash[3] = "three"
      (@hash + other_hash).values.must ==
        ["Foo!", "Bar!", "Baz!", "Bop!", "Bat!", "one", "two", "three"]
    end

    it "shouldn't overwrite hash keys with matching appended keys" do
      other_hash = Thor::CoreExt::OrderedHash.new
      other_hash[:bar] = "bar"
      (@hash + other_hash)[:bar].must == "Bar!"
    end
  end
end
