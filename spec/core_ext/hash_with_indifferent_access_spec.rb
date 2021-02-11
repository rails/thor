require "helper"
require "thor/core_ext/hash_with_indifferent_access"

describe Thor::CoreExt::HashWithIndifferentAccess do
  before do
    @hash = Thor::CoreExt::HashWithIndifferentAccess.new :foo => "bar", "baz" => "bee", :force => true
  end

  it "has values accessible by either strings or symbols" do
    expect(@hash["foo"]).to eq("bar")
    expect(@hash[:foo]).to eq("bar")

    expect(@hash.values_at(:foo, :baz)).to eq(%w(bar bee))
    expect(@hash.delete(:foo)).to eq("bar")
  end

  it "supports except" do
    unexcepted_hash = @hash.dup
    @hash.except("foo")
    expect(@hash).to eq(unexcepted_hash)

    expect(@hash.except("foo")).to eq("baz" => "bee", "force" => true)
    expect(@hash.except("foo", "baz")).to eq("force" => true)
    expect(@hash.except(:foo)).to eq("baz" => "bee", "force" => true)
    expect(@hash.except(:foo, :baz)).to eq("force" => true)
  end

  it "supports fetch" do
    expect(@hash.fetch("foo")).to eq("bar")
    expect(@hash.fetch("foo", nil)).to eq("bar")
    expect(@hash.fetch(:foo)).to eq("bar")
    expect(@hash.fetch(:foo, nil)).to eq("bar")

    expect(@hash.fetch("baz")).to eq("bee")
    expect(@hash.fetch("baz", nil)).to eq("bee")
    expect(@hash.fetch(:baz)).to eq("bee")
    expect(@hash.fetch(:baz, nil)).to eq("bee")

    expect { @hash.fetch(:missing) }.to raise_error(IndexError)
    expect(@hash.fetch(:missing, :found)).to eq(:found)
  end

  it "has key checkable by either strings or symbols" do
    expect(@hash.key?("foo")).to be true
    expect(@hash.key?(:foo)).to be true
    expect(@hash.key?("nothing")).to be false
    expect(@hash.key?(:nothing)).to be false
  end

  it "handles magic boolean predicates" do
    expect(@hash.force?).to be true
    expect(@hash.foo?).to be true
    expect(@hash.nothing?).to be false
  end

  it "handles magic comparisons" do
    expect(@hash.foo?("bar")).to be true
    expect(@hash.foo?("bee")).to be false
  end

  it "maps methods to keys" do
    expect(@hash.foo).to eq(@hash["foo"])
  end

  it "merges keys independent if they are symbols or strings" do
    @hash["force"] = false
    @hash[:baz] = "boom"
    expect(@hash[:force]).to eq(false)
    expect(@hash["baz"]).to eq("boom")
  end

  it "creates a new hash by merging keys independent if they are symbols or strings" do
    other = @hash.merge("force" => false, :baz => "boom")
    expect(other[:force]).to eq(false)
    expect(other["baz"]).to eq("boom")
  end

  it "converts to a traditional hash" do
    expect(@hash.to_hash.class).to eq(Hash)
    expect(@hash).to eq("foo" => "bar", "baz" => "bee", "force" => true)
  end

  it "handles reverse_merge" do
    other = {:foo => "qux", "boo" => "bae"}
    new_hash = @hash.reverse_merge(other)

    expect(@hash.object_id).not_to eq(new_hash.object_id)
    expect(new_hash[:foo]).to eq("bar")
    expect(new_hash[:boo]).to eq("bae")
  end

  it "handles reverse_merge!" do
    other = {:foo => "qux", "boo" => "bae"}
    new_hash = @hash.reverse_merge!(other)

    expect(@hash.object_id).to eq(new_hash.object_id)
    expect(new_hash[:foo]).to eq("bar")
    expect(new_hash[:boo]).to eq("bae")
  end
end
