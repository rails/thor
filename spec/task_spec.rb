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
      klass = mock!.class_options{{ :bar => Thor::Option.parse(:bar, :required) }}.subject
      task('foo' => true).formatted_usage(klass, false).must == "can_has [--foo] --bar=BAR"
    end

    it "includes namespace within usage" do
      stub(Object).class_options{{ :bar => Thor::Option.parse(:bar, :required) }}
      stub(Object).namespace{ "string" }
      task.formatted_usage(Object, true).must == "string:can_has --bar=BAR"
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

  describe "#run" do
    it "runs a task by invoking it in the given instance" do
      mock = mock!.invoke(:task, 1, 2, 3).subject
      task.run(mock, [1, 2, 3])
    end

    it "raises an error if the method to be invoked is private" do
      mock = mock!.private_methods{ [ "task" ] }.subject
      lambda {
        task.run(mock)
      }.must raise_error(NoMethodError, "the 'task' task of Object is private")
    end
  end

  describe "#parse" do
    it "parses arguments and options using task options declaration" do
      stub(Object).class_options{ { } }
      task('foo' => true, :bar => :required)
      args, options = task.parse(Object, ["--bar", "cool", "--foo"])

      args.must == []
      options.must == {"bar" => "cool", "foo" => true}
    end

    it "parses arguments and options using class default options" do
      stub(Object).class_options{{ :bar => Thor::Option.parse(:bar, :required),
                                     :foo => Thor::Option.parse(:foo, true) }}
      args, options = task.parse(Object, ["--bar", "cool", "--foo", "left"])

      args.must == ["left"]
      options.must == {"bar" => "cool", "foo" => true}
    end

    it "parses arguments and options using class and task options" do
      stub(Object).class_options{{ :bar => Thor::Option.parse(:bar, :required) }}
      args, options = task(:foo => true).parse(Object, ["--bar", "cool", "--foo", "left"])

      args.must == ["left"]
      options.must == {"bar" => "cool", "foo" => true}
    end

    it "parses arguments and options using tasks options with higher priority than class options" do
      stub(Object).class_options{{ :bar => Thor::Option.parse(:bar, :required),
                                     :foo => Thor::Option.parse(:foo, :string) }}
      args, options = task(:foo => true).parse(Object, ["--bar", "cool", "--foo"])

      args.must == []
      options.must == {"bar" => "cool", "foo" => true}
    end
  end
end
