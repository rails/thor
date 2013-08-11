require 'helper'

describe Thor::LineEditor::Basic do
  describe '.available?' do
    it 'returns true' do
      expect(Thor::LineEditor::Basic).to be_available
    end
  end

  describe '#readline' do
    it 'uses $stdin and $stdout to get input from the user' do
      expect($stdout).to receive(:print).with('Enter your name ')
      expect($stdin).to receive(:gets).and_return('George')
      editor = Thor::LineEditor::Basic.new('Enter your name ', {})
      expect(editor.readline).to eq('George')
    end
  end
end
