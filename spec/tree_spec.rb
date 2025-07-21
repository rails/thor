require "helper"
require "thor"

class TreeApp < Thor
  desc "command1", "A top level command"

  def command1
  end

  desc "command2", "Another top level command"

  def command2
  end

  class SubApp < Thor
    desc "subcommand1", "A subcommand"

    def subcommand1
    end
  end

  desc "sub", "Subcommands"
  subcommand "sub", SubApp
end

RSpec.describe "Thor tree command" do
  let(:shell) { Thor::Shell::Basic.new }

  it "prints a tree of all commands" do
    expect(capture(:stdout) { TreeApp.start(["tree"]) }).to match(/├─ command1/)
    expect(capture(:stdout) { TreeApp.start(["tree"]) }).to match(/├─ command2/)
    expect(capture(:stdout) { TreeApp.start(["tree"]) }).to match(/└─ sub/)
    expect(capture(:stdout) { TreeApp.start(["tree"]) }).to match(/subcommand1/)
  end

  it "includes command descriptions" do
    expect(capture(:stdout) { TreeApp.start(["tree"]) }).to match(/A top level command/)
    expect(capture(:stdout) { TreeApp.start(["tree"]) }).to match(/Another top level command/)
    expect(capture(:stdout) { TreeApp.start(["tree"]) }).to match(/A subcommand/)
  end

  it "doesn't show hidden commands" do
    expect(capture(:stdout) { TreeApp.start(["tree"]) }).not_to match(/help/)
  end

  it "shows tree command in help" do
    expect(capture(:stdout) { TreeApp.start(["help"]) }).to match(/tree.*Print a tree of all available commands/)
  end
end
