require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Thor::Task do
  def task(options={})
    options.each do |key, value|
      options[key] = Thor::Option.parse(key, value)
    end

    @task ||= Thor::Task.new(:can_has, "I can has cheezburger", "can_has", options)
  end

  describe "#formatted_usage" do
    it "shows usage with options" do
      task('foo' => true, :bar => :required).formatted_usage.must == "can_has --bar=BAR [--foo]"
    end

    it "includes namespace within usage" do
      stub(Object).namespace{ "foo" }
      stub(Object).arguments{ [] }
      task(:bar => :required).formatted_usage(Object, true).must == "foo:can_has --bar=BAR"
    end

    it "removes default from namespace" do
      stub(Object).namespace{ "default:foo" }
      stub(Object).arguments{ [] }
      task(:bar => :required).formatted_usage(Object, true).must == ":foo:can_has --bar=BAR"
    end

    it "injects arguments into usage" do
      stub(Object).namespace{ "foo" }
      stub(Object).arguments{ [ Thor::Argument.new(:bar, nil, true, :string) ] }
      task(:foo => true).formatted_usage(Object).must == "can_has BAR [--foo]"
    end
  end

  describe "#dynamic" do
    it "creates a dynamic task with the given name" do
      Thor::Task.dynamic('task').name.must == 'task'
      Thor::Task.dynamic('task').description.must == 'A dynamically-generated task'
      Thor::Task.dynamic('task').usage.must == 'task'
      Thor::Task.dynamic('task').options.must == {}
    end
  end

  describe "#dup" do
    it "dup options hash" do
      task = Thor::Task.new("can_has", nil, nil, :foo => true, :bar => :required)
      task.dup.options.delete(:foo)
      task.options[:foo].must_not be_nil
    end

    it "dup conditions hash" do
      task = Thor::Task.new("can_has", nil, nil, {}, :foo => true, :bar => :required)
      task.dup.conditions.delete(:foo)
      task.conditions[:foo].must_not be_nil
    end
  end

  describe "#run" do
    it "runs a task by calling a method in the given instance" do
      mock = mock!.send("can_has", 1, 2, 3).subject
      task.run(mock, [1, 2, 3])
    end

    it "raises an error if the method to be invoked is private" do
      mock = mock!.private_methods{ [ 'can_has' ] }.subject
      lambda {
        task.run(mock)
      }.must raise_error(Thor::UndefinedTaskError, "the 'can_has' task of Object is private")
    end
  end

  describe "#short_description" do
    it "returns the first line of the description" do
      Thor::Task.new(:task, "I can has\ncheezburger", "can_has").short_description == "I can has"
    end

    it "returns the whole description if it's one line" do
      Thor::Task.new(:task, "I can has cheezburger", "can_has").short_description == "I can has cheezburger"
    end
  end

  describe "#valid_conditions?" do
    def run(instance, conditions={})
      Thor::Task.new(:can_has, "I can has cheezburger", "can_has", nil, conditions).run(instance)
    end

    def stub!(options={})
      instance = Object.new
      stub(instance).options{ options }
      instance
    end

    it "runs the task if no conditions are given" do
      instance = stub!
      mock(instance).can_has
      run(instance)
    end

    it "runs the task if conditions are met" do
      instance = stub!(:with_conditions => true)
      mock(instance).can_has
      run(instance, :with_conditions => true)
    end

    it "does not run the task if conditions are not met" do
      instance = stub!(:with_conditions => true)
      dont_allow(instance).can_has
      run(instance, :with_conditions => false)
    end

    it "runs the task if symbol is equivalent to the given string" do
      instance = stub!(:framework => :rails)
      mock(instance).can_has
      run(instance, :framework => "rails")

      instance = stub!(:framework => "rails")
      mock(instance).can_has
      run(instance, :framework => :rails)

      instance = stub!(:framework => :rails)
      mock(instance).can_has
      run(instance, :framework => :rails)
    end

    it "does not run the task if strings does not match" do
      instance = stub!(:framework => "merb")
      dont_allow(instance).can_has
      run(instance, :framework => "rails")
    end

    it "runs the task if regexp matches" do
      instance = stub!(:framework => "rails")
      mock(instance).can_has
      run(instance, :framework => /rails/)
    end

    it "does not run the task if regexp matches" do
      instance = stub!(:framework => "merb")
      dont_allow(instance).can_has
      run(instance, :framework => /rails/)
    end

    it "runs the task if value is included in array" do
      instance = stub!(:framework => "rails")
      mock(instance).can_has
      run(instance, :framework => [:rails, :merb])
    end

    it "does not run the task if value is not included in array" do
      instance = stub!(:framework => "sinatra")
      dont_allow(instance).can_has
      run(instance, :framework => [:rails, :merb])
    end
  end
end
