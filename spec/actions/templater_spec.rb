require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'thor/actions'

describe Thor::Actions::Templater do

  def templater(source, destination=nil)
    @base = begin
      base = Object.new
      stub(base).source_root{ source_root }
      stub(base).destination_root{ destination_root }
      base
    end

    @action = Thor::Actions::Templater.new(base, source, destination || source)
  end

  describe "#source" do
    it "sets the source based on the source root" do
      templater('task.thor').source.must == File.join(source_root, 'task.thor')
    end
  end

  describe "#destination" do
    it "uses the source as default destination" do
      templater('task.thor').destination.must == File.join(destination_root, 'task.thor')
    end

    it "allows the destination to be set" do
      templater('task.thor', 'foo.thor').destination.must == File.join(destination_root, 'foo.thor')
    end

    it "sets the destination based on the destination root" do
      templater('task.thor', 'task.thor').destination.must == File.join(destination_root, 'task.thor')
    end
  end

  describe "#relative_destination" do
    it "stores the relative destination given" do
      templater('task.thor').relative_destination.must == 'task.thor'
    end
  end
end
