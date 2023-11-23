require "helper"
require "readline"

describe Thor::LineEditor, "on a system with Readline support" do
  before do
    @original_readline = ::Readline
    Object.send(:remove_const, :Readline)
    ::Readline = double("Readline")
  end

  after do
    Object.send(:remove_const, :Readline)
    ::Readline = @original_readline
  end

  describe ".readline" do
    it "uses the Readline line editor" do
      editor = double("Readline")
      expect(Thor::LineEditor::Readline).to receive(:new).with("Enter your name ", {default: "Brian"}).and_return(editor)
      expect(editor).to receive(:readline).and_return("George")
      expect(Thor::LineEditor.readline("Enter your name ", default: "Brian")).to eq("George")
    end
  end
end

describe Thor::LineEditor, "on a system without Readline support" do
  before do
    @original_readline = ::Readline
    Object.send(:remove_const, :Readline)
  end

  after do
    ::Readline = @original_readline
  end

  describe ".readline" do
    it "uses the Basic line editor" do
      editor = double("Basic")
      expect(Thor::LineEditor::Basic).to receive(:new).with("Enter your name ", {default: "Brian"}).and_return(editor)
      expect(editor).to receive(:readline).and_return("George")
      expect(Thor::LineEditor.readline("Enter your name ", default: "Brian")).to eq("George")
    end
  end
end
