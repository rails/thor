require File.dirname(__FILE__) + '/spec_helper'
require "thor"
require "thor/task"

describe Thor::Task do
  it "#formatted_usage" do
    opts = { 'foo' => true, :bar => :required }
    @task = Thor::Task.new(nil, "I can has cheezburger", "can_has", opts, nil)
    @task.formatted_usage.must == "can_has [--foo] --bar=BAR"
  end
end
