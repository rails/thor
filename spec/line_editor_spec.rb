require 'helper'

describe Thor::LineEditor do
  describe '#readline' do
    it 'uses $stdout and $stdin to prompt the user for input' do
      expect($stdout).to receive(:print).with('Enter your name ')
      expect($stdin).to receive(:gets).and_return('George')
      expect(Thor::LineEditor.readline('Enter your name ')).to eq('George')
    end
  end
end
