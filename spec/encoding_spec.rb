require "helper"
require "thor/base"


describe "file's encoding" do
  def load_thorfile(filename)
    Thor::Util.load_thorfile(File.expand_path("./fixtures/#{filename}", __dir__))
  end

  it "respects explicit UTF-8" do
    load_thorfile("encoding_with_utf8.thor")
    expect(capture(:stdout) { Thor::Sandbox::EncodingWithUtf8.new.invoke(:encoding) }).to match(/ok/)
  end
  it "respects explicit non-UTF-8" do
    load_thorfile("encoding_other.thor")
    expect(capture(:stdout) { Thor::Sandbox::EncodingOther.new.invoke(:encoding) }).to match(/ok/)
  end
  it "has implicit UTF-8" do
    load_thorfile("encoding_implicit.thor")
    expect(capture(:stdout) { Thor::Sandbox::EncodingImplicit.new.invoke(:encoding) }).to match(/ok/)
  end
end
