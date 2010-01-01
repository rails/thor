require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Thor::Task do
  def task(options={})
    options.each do |key, value|
      options[key] = Thor::Option.parse(key, value)
    end

    @task ||= Thor::Task.new(:can_has, "I can has cheezburger", "can_has", options)
  end

  describe "#formatted_usage" do
    it "includes namespace within usage" do
      stub(Object).namespace{ "foo" }
      stub(Object).arguments{ [] }
      task(:bar => :required).formatted_usage(Object).must == "foo:can_has --bar=BAR"
    end

    it "removes default from namespace" do
      stub(Object).namespace{ "default:foo" }
      stub(Object).arguments{ [] }
      task(:bar => :required).formatted_usage(Object).must == ":foo:can_has --bar=BAR"
    end

    it "injects arguments into usage" do
      stub(Object).namespace{ "foo" }
      stub(Object).arguments{ [ Thor::Argument.new(:bar, nil, true, :string) ] }
      task(:foo => :required).formatted_usage(Object).must == "foo:can_has BAR --foo=FOO"
    end
  end

  describe "#dynamic" do
    it "creates a dynamic task with the given name" do
      Thor::Task::Dynamic.new('task').name.must == 'task'
      Thor::Task::Dynamic.new('task').description.must == 'A dynamically-generated task'
      Thor::Task::Dynamic.new('task').usage.must == 'task'
      Thor::Task::Dynamic.new('task').options.must == {}
    end

    it "does not invoke an existing method" do
      lambda {
        Thor::Task::Dynamic.new('to_s').run([])
      }.must raise_error(Thor::Error, "could not find Thor class or task 'to_s'")
    end
  end

  describe "#dup" do
    it "dup options hash" do
      task = Thor::Task.new("can_has", nil, nil, :foo => true, :bar => :required)
      task.dup.options.delete(:foo)
      task.options[:foo].must_not be_nil
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
end
