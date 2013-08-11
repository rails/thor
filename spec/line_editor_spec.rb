require 'helper'

describe Thor::LineEditor, 'on a system with Readline support' do
  before do
    @original_readline = ::Readline if defined? ::Readline
    silence_warnings { ::Readline = double('Readline') }
  end

  after do
    silence_warnings { ::Readline = @original_readline }
  end

  describe '.readline' do
    it 'invokes the Readline library' do
      expect(Readline).to receive(:readline).with('Enter your name ').and_return('George')
      expect(Thor::LineEditor.readline('Enter your name ')).to eq('George')
    end
  end
end

describe Thor::LineEditor, 'on a system without Readline support' do
  before do
    if defined? ::Readline
      @original_readline = ::Readline
      Object.send(:remove_const, :Readline)
    end
  end

  after do
    silence_warnings { ::Readline = @original_readline }
  end

  describe '.readline' do
    it 'uses $stdout and $stdin to prompt the user for input' do
      expect($stdout).to receive(:print).with('Enter your name ')
      expect($stdin).to receive(:gets).and_return('George')
      expect(Thor::LineEditor.readline('Enter your name ')).to eq('George')
    end
  end
end
