require File.dirname(__FILE__) + '/spec_helper'
require "thor"
require "thor/task"

describe "thor task" do
  describe "#formatted_opts" do
    def create(opts)
      @task = Thor::Task.new(nil, nil, nil, opts, nil)
    end
    
    def result
      @task.formatted_opts
    end
    
    it "formats optional args with sample values" do
      create "--repo" => :optional, "--branch" => "bugfix"
      result.must == "[--repo=REPO] [--branch=bugfix]"
    end
  end
end
