require 'helper'

describe Thor::LineEditor::Readline do
  before do
    unless defined? ::Readline
      ::Readline = double('Readline')
    end
  end

  describe '.available?' do
    it 'returns true when ::Readline exists' do
      allow(Kernel).to receive(:const_defined?).with(:Readline).and_return(true)
      expect(described_class).to be_available
    end

    it 'returns false when ::Readline does not exist' do
      allow(Kernel).to receive(:const_defined?).with(:Readline).and_return(false)
      expect(described_class).not_to be_available
    end
  end

  describe '#readline' do
    it 'invokes the readline library' do
      expect(::Readline).to receive(:readline).with('> ', true).and_return('foo')
      editor = Thor::LineEditor::Readline.new('> ', {})
      expect(editor.readline).to eq('foo')
    end

    it 'supports the add_to_history option' do
      expect(::Readline).to receive(:readline).with('> ', false).and_return('foo')
      editor = Thor::LineEditor::Readline.new('> ', :add_to_history => false)
      expect(editor.readline).to eq('foo')
    end
  end
end
