require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Thor::Task do
  def task(options={})
    options.each do |key, value|
      options[key] = Thor::Option.parse(key, value)
    end

    @task ||= Thor::Task.new(:task, "I can has cheezburger", "can_has", options)
  end

  describe "#formatted_usage" do
    it "shows usage with options" do
      task('foo' => true, :bar => :required).formatted_usage.must == "can_has [--foo] --bar=BAR"
    end

    it "includes class options if a class is given" do
      klass = mock!.default_options{{ :bar => Thor::Option.parse(:bar, :required) }}.subject
      task('foo' => true).formatted_usage(klass, false).must == "can_has [--foo] --bar=BAR"
    end

    it "includes namespace within usage" do
      stub(String).default_options{{ :bar => Thor::Option.parse(:bar, :required) }}
      task.formatted_usage(String, true).must == "string:can_has --bar=BAR"
    end
  end

  describe "#dynamic" do
    it "creates a dynamic task with the given name" do
      Thor::Task.dynamic('task').name.must == 'task'
      Thor::Task.dynamic('task').description.must == 'A dynamically-generated task'
      Thor::Task.dynamic('task').usage.must == 'task'
      Thor::Task.dynamic('task').options.must be_nil
    end
  end

  describe "#clone" do
    it "clones options hash" do
      new_task = task(:foo => true, :bar => :required).clone
      new_task.options.delete(:foo)
      task.options[:foo].must_not be_nil
    end
  end
end
