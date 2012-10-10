require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'thor/base'

describe "Exit conditions" do
  it "exits 0, not bubble up EPIPE, if EPIPE is raised" do
    epiped = false

    task = Class.new(Thor) do
      desc "my_action", "testing EPIPE"
      define_method :my_action do
        epiped = true
        raise Errno::EPIPE
      end
    end

    expect{ task.start(["my_action"]) }.to raise_error(SystemExit)
    expect(epiped).to eq(true)
  end
end
