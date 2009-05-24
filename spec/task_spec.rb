require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Thor::Task do
  def task_with_mock(options={})
    @klass = Class.new
    stub(@klass).opts { {} }
    Thor::Task.new(:method, "I can has cheezburger", "can_has", options, @klass)
  end

  describe "#formatted_usage" do
    it "shows usage with options" do
      @task = task_with_mock('foo' => true, :bar => :required)
      @task.formatted_usage.must == "can_has [--foo] --bar=BAR"
    end

    it "should include class options" do
      @task = task_with_mock('foo' => true)
      stub(@klass).opts{ { :bar => :required } }
      @task.formatted_usage.must == "can_has [--foo] --bar=BAR"
    end
  end

  describe "#parse" do
    it "parses given arguments and calls the given klass" do
      @task = task_with_mock('foo' => true)
      stub(@klass).opts{ { :bar => :required } }

      obj = Object.new
      mock(obj).options = { "foo"=>true, "bar"=>"AWESOME" }
      mock(obj).invoke(:method, "bla")

      @task.parse(obj, ["bla", "--foo", "--bar=AWESOME"])
    end
  end
end
