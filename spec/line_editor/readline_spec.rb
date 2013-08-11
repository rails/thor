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
      expect(::Readline).to receive(:completion_proc=).with(nil)
      editor = Thor::LineEditor::Readline.new('> ', {})
      expect(editor.readline).to eq('foo')
    end

    it 'supports the add_to_history option' do
      expect(::Readline).to receive(:readline).with('> ', false).and_return('foo')
      expect(::Readline).to receive(:completion_proc=).with(nil)
      editor = Thor::LineEditor::Readline.new('> ', :add_to_history => false)
      expect(editor.readline).to eq('foo')
    end

    it 'provides tab completion when given a limited_to option' do
      expect(::Readline).to receive(:readline)
      expect(::Readline).to receive(:completion_proc=) do |proc|
        expect(proc.call('')).to eq ['Apples', 'Chicken', 'Chocolate']
        expect(proc.call('Ch')).to eq ['Chicken', 'Chocolate']
        expect(proc.call('Chi')).to eq ['Chicken']
      end

      editor = Thor::LineEditor::Readline.new('Best food: ', :limited_to => ['Apples', 'Chicken', 'Chocolate'])
      editor.readline
    end
  end
end
