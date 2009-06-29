class Thor
  module Invocation

    # Make initializer aware of invocations and the initializer proc.
    #
    def initialize(args=[], options={}, config={}, &block) #:nodoc:
      @_invocations = config[:invocations] || Hash.new { |h,k| h[k] = [] }
      @_initializer = block || lambda do |klass, invoke, overrides|
        klass.new(args, options, config.merge(overrides))
      end
      super
    end

    # Receives a name and invokes it. The name can be a string (either "task" or
    # "namespace:task"), a Thor::Task, a Class or a Thor instance. If the task
    # cannot be guessed name, it can also be supplied as second argument. The
    # arguments used to invoke the task are always supplied as the last argument.
    #
    # ==== Examples
    #
    #   class A < Thor
    #     def foo
    #       invoke :bar
    #       invoke "b:hello", ["José"]
    #     end
    #
    #     def bar
    #       invoke "b:hello", ["José"]
    #     end
    #   end
    #
    #   class B < Thor
    #     def hello(name)
    #       puts "hello #{name}"
    #     end
    #   end
    #
    # You can notice that the method "foo" above invokes two tasks: "bar",
    # which belongs to the same class and "hello" which belongs to the class B.
    #
    # By using an invocation system you ensure that a task is invoked only once.
    # In the example above, invoking "foo" will invoke "b:hello" just once, even
    # if it's invoked later by "bar" method.
    #
    # When class A invokes class B, all arguments used on A initialization are
    # supplied to B. This allows lazy parse of options. Let's suppose you have
    # some rspec tasks:
    #
    #   class Rspec < Thor::Group
    #     class_option :mock_framework, :type => :string, :default => :rr
    #
    #     def invoke_mock_framework
    #       invoke "rspec:#{options[:mock_framework]}"
    #     end
    #   end
    #
    # As you notice, it invokes the given mock framework, which might have its
    # own options:
    #
    #   class Rspec::RR < Thor::Group
    #     class_option :style, :type => :string, :default => :mock
    #   end
    #
    # Since it's not rspec concern to parse mock framework options, when RR
    # is invoked all options are parsed again, so RR can extract only the options
    # that it's going to use.
    #
    # If you want Rspec::RR to be initialized with its own set of options, you
    # have to do that explicitely:
    #
    #   invoke Rspec::RR.new([], :style => :foo)
    #
    # Besides giving an instance, you can also give a class to invoke:
    #
    #   invoke Rspec::RR
    #
    # Or even a class, the task to invoke from it and its arguments:
    #
    #   invoke Rspec::RR, :foo, [ args ]
    #
    def invoke(name=nil, task=nil, method_args=nil)
      task, method_args = nil, task if task.is_a?(Array)
      object, task = _setup_for_invoke(name, task)

      if object.is_a?(Class)
        klass = object
        instance, trailing = @_initializer.call(klass, task, _shared_config)
        method_args ||= trailing
      else
        klass, instance = object.class, object
      end

      method_args ||= []
      current = @_invocations[klass]

      iterator = lambda do |_, task|
        unless current.include?(task.name)
          current << task.name
          task.run(instance, method_args)
        end
      end

      if task
        iterator.call(nil, task)
      else
        method_args = []
        klass.all_tasks.map(&iterator)
      end
    end

    protected

      # Values that are sent to overwrite defined configuration values.
      #
      def _shared_config #:nodoc:
        { :invocations => @_invocations }
      end

      # This is the method responsable for retrieving and setting up an
      # instance to be used in invoke.
      #
      def _setup_for_invoke(name, sent_task=nil) #:nodoc:
        case name
          when Thor::Task
            task = name
          when Symbol, String
            name = name.to_s

            begin
              task = self.class.all_tasks[name]
              object, task = Thor::Util.namespace_to_thor_class(name) unless task
              task = task || sent_task
            rescue Thor::Error
              task = name
            end
          else
            object, task = name, sent_task
        end

        object ||= self
        klass = object.is_a?(Class) ? object : object.class
        raise "Expected Thor class, got #{klass}" unless klass <= Thor::Base

        task ||= klass.default_task if klass <= Thor
        task = klass.all_tasks[task.to_s] || Task.dynamic(task) if task && !task.is_a?(Thor::Task)
        return object, task
      end

  end
end
