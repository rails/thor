require "helper"
require "thor/core_ext/ordered_hash"

describe Thor::CoreExt::OrderedHash do
  subject { Thor::CoreExt::OrderedHash.new }

  def populate_subject
    subject[:foo] = "Foo!"
    subject[:bar] = "Bar!"
    subject[:baz] = "Baz!"
    subject[:bop] = "Bop!"
    subject[:bat] = "Bat!"
  end

  describe "#initialize" do
    it "is empty" do
      expect(subject).to be_empty
    end
  end

  describe "#replace" do
    before { populate_subject }
    it "replaces the keys" do
      other_hash = Thor::CoreExt::OrderedHash.new
      other_hash[1] = "one"
      other_hash[2] = "two"
      other_hash[3] = "three"

      subject.replace(other_hash)
      expect(subject.keys).to eq [1,2,3]
    end
  end

  describe "#[]" do
    it "returns nil for an undefined key" do
      expect(subject[:boom]).to be nil
    end

    before { populate_subject }
    it "returns the value for each key" do
      expect(subject[:foo]).to eq "Foo!"
    end
  end

  describe "#[]=" do
    it "does not duplicate keys" do
      subject[:key] = 1
      subject[:key] = 2

      expect(subject.keys.size).to eq 1
      expect(subject[:key]).to eq 2
    end

   it "does not move an overwritten node to the end of the ordering" do
     populate_subject

     subject[:baz] = "Bip!"
     expect(subject.values).to eq(["Foo!", "Bar!", "Bip!", "Bop!", "Bat!"])

     subject[:foo] = "Bip!"
     expect(subject.values).to eq(["Bip!", "Bar!", "Bip!", "Bop!", "Bat!"])

     subject[:bat] = "Bip!"
     expect(subject.values).to eq(["Bip!", "Bar!", "Bip!", "Bop!", "Bip!"])
   end
  end

  describe "#clear" do
    before { populate_subject }
    it "clears the keys" do
      subject.clear
      expect(subject.keys).to be_empty
    end
  end

  describe "#shift" do
    before { populate_subject }
    it "pops the first key/value" do
      arr = subject.shift
      expect(arr).to eq [:foo, "Foo!"]
    end

    it "removes the key" do
      subject.shift
      expect(subject.keys).to_not include(:foo)
    end
  end

  describe "#each" do
    before { populate_subject }
    it "iterates through the keys and values in order of assignment" do
      arr = []
      subject.each do |key, value|
        arr << [key, value]
      end

     expect(arr).to eq([[:foo, "Foo!"], [:bar, "Bar!"], [:baz, "Baz!"],
                        [:bop, "Bop!"], [:bat, "Bat!"]])
    end
  end

  describe "#merge!" do
    it "modifies the existing object" do
      populate_subject

      other_hash = Thor::CoreExt::OrderedHash.new
      other_hash[1] = "one"
      other_hash[2] = "two"
      other_hash[3] = "three"

      subject.merge!(other_hash)

      expect(subject.values).to eq(["Foo!", "Bar!", "Baz!", "Bop!", "Bat!", "one", "two", "three"])
    end
  end

  describe "#merge" do
    it "appends another ordered hash while preserving ordering" do
      populate_subject

      other_hash = Thor::CoreExt::OrderedHash.new
      other_hash[1] = "one"
      other_hash[2] = "two"
      other_hash[3] = "three"


      merged_list = subject.merge(other_hash)
      expect(merged_list.values).to eq(["Foo!", "Bar!", "Baz!", "Bop!", "Bat!", "one", "two", "three"])
    end

    it "overwrites hash keys with matching appended keys" do
      populate_subject

      other_hash = Thor::CoreExt::OrderedHash.new
      other_hash[:bar] = "bar"

      expect(subject.merge(other_hash)[:bar]).to eq("bar")
      expect(subject[:bar]).to eq("Bar!")
    end
  end

  describe "#to_a" do
    before { populate_subject }
    it "converts to an array" do
      expect(subject.to_a).to eq([[:foo, "Foo!"], [:bar, "Bar!"], [:baz, "Baz!"], [:bop, "Bop!"], [:bat, "Bat!"]])
    end
  end

  describe "#keys" do
    context "when list is unpopulated" do
      it "has an empty keys list" do
        expect(subject.keys).to be_empty
      end
    end

    it "returns the keys in order of insertion" do
      populate_subject
      expect(subject.keys).to eq([:foo, :bar, :baz, :bop, :bat])
    end
  end

  describe "#values" do
    it "returns the values in order of insertion" do
      populate_subject
      expect(subject.values).to eq(["Foo!", "Bar!", "Baz!", "Bop!", "Bat!"])
    end

    context "when list is unpopulated" do
      it "has an empty list" do
        list = described_class.new
        expect(list.values).to be_empty
      end
    end
  end

  describe "#delete" do
    before { populate_subject }
    it "deletes the value given the key" do
      expect(subject.delete(:baz)).to eq("Baz!")
      expect(subject.values).to eq(["Foo!", "Bar!", "Bop!", "Bat!"])

      expect(subject.delete(:foo)).to eq("Foo!")
      expect(subject.values).to eq(["Bar!", "Bop!", "Bat!"])

      expect(subject.delete(:bat)).to eq("Bat!")
      expect(subject.values).to eq(["Bar!", "Bop!"])
    end

    it "returns nil if the value to be deleted can't be found" do
      expect(subject.delete(:nothing)).to be nil
    end

    it "deletes the given key" do
      subject.delete(:baz)
      expect(subject.keys).to_not include(:baz)
    end
  end
end
