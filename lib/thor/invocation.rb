class Thor
  module Invocation

    def initialize(args=[], options={}, config={}, &block)
      @_initializer = block || lambda do |klass, invoke|
        klass.new(args, options, config)
      end
      super
    end

    # Receives a name and invokes it. The name can be either a namespaced name,
    # a current class task or even a class. Arguments are given in an array and
    # options given are merged with the invoker options.
    #
    # ==== Examples
    #
    #   class A < Thor
    #     def foo
    #       invoke :bar
    #       invoke "b:lib", ["merb", "rails"]
    #     end
    #
    #     def bar
    #       invoke "b:lib", ["merb", "rails"]
    #       # magic
    #     end
    #   end
    #
    #   class B < Thor
    #     argument :preferred_framework, :type => :string
    #
    #     def lib(second_framework)
    #       # magic
    #     end
    #   end
    #
    # You can notice that the method "foo" above invokes two tasks: "bar",
    # which belongs to the same class and "lib" that belongs to the class B.
    #
    # By using an invocation system you ensure that a task is invoked only once.
    # In the example above, invoking foo will invoke "b:lib" just once, even if
    # it's invoked later by "bar" method.
    #
    # When invoking another class, there are a few things to keep in mind:
    #
    #   1) Class arguments are parsed first. In the example above, preferred
    #      framework is going to consume "merb" and second framework is going
    #      to be set to "rails".
    #
    #   2) All options and configurations are sent to the invoked class.
    #      So the invoked class is going to use the same shell instance, will
    #      have the same behavior (:invoke or :revoke) and so on.
    #
    # Invoking a Thor::Group happens in the same away as above:
    #
    #   class C < Thor::Group
    #     def one
    #     end
    #   end
    #
    # Is invoked as:
    #
    #   invoke "c"
    #
    # Or even as:
    #
    #   invoke C
    #
    def invoke(object, method_args=nil)
      @_invocations ||= Hash.new { |h,k| h[k] = [] }

      object, task = _setup_for_invoke(object)

      if object.is_a?(Class)
        klass = object
        instance, trailing = @_initializer.call(klass, task)
        instance.instance_variable_set('@_invocations', @_invocations)
        method_args ||= trailing
      else
        klass, instance = object.class, object
      end

      current = @_invocations[klass]
      return if current.include?("all")

      if task
        return if current.include?(task.name)
        current << task.name
        task.run(instance, method_args || [])
      else
        current << "all"
        klass.all_tasks.collect { |_, task| task.run(instance) }
      end
    end

    protected

      # This is the method responsable for retrieving and setting up an
      # instance to be used in invoke.
      #
      def _setup_for_invoke(name) #:nodoc:
        case name
          when Thor::Task
            task = name
          when Symbol, String
            task = name.to_s

            if thor_task = self.class.all_tasks[task]
              object, task = self, thor_task
            else
              object, task = Thor::Util.namespace_to_thor_class(task) rescue Thor::Error
            end
          else
            object = name
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
