class Thor
  module Invocation

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
    def invoke(name, method_args=[], options={})
      @_invocations ||= Hash.new { |h,k| h[k] = [] }
      instance, task = _setup_for_invoke(name, method_args, options)

      current = @_invocations[instance.class]
      return if current.include?("all")

      if task
        task = self.class.all_tasks[task.to_s] || Task.dynamic(task) unless task.is_a?(Thor::Task)
        return if current.include?(task.name)

        current << task.name
        task.run(instance, method_args)
      else
        current << "all"
        instance.class.all_tasks.collect { |_, task| task.run(instance) }
      end
    end

    protected

      # This is the method responsable for retrieving and setting up an
      # instance to be used in invoke.
      #
      def _setup_for_invoke(name, method_args, options) #:nodoc:
        case name
          when NilClass, Thor::Task
            # Do nothing, we already have what we want
          when Class
            klass = name
          else
            name = name.to_s
            unless self.class.all_tasks[name]
              klass, task = Thor::Util.namespace_to_thor_class(name) rescue Thor::Error
            end
        end

        if klass.nil?
          return self, name
        elsif klass <= Thor::Base
          size       = klass.arguments.size
          class_args = method_args.slice!(0, size)
          instance   = klass.new(class_args, self.options.merge(options), _dump_config)

          task ||= klass.default_task if klass <= Thor
          instance.instance_variable_set("@_invocations", @_invocations)

          return instance, task
        else
          raise "Expected Thor class, got #{klass}"
        end
      end

      # Dump the configuration values for this current class.
      #
      def _dump_config #:nodoc:
        { :shell => self.shell }
      end

  end
end
