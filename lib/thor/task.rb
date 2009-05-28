class Thor
  class Task < Struct.new(:name, :description, :usage, :options)

    # Creates a dynamic task. Dynamic tasks are created on demand to allow method
    # missing calls (since a method missing does not have a task object for it).
    #
    def self.dynamic(name)
      new(name, "A dynamically-generated task", name.to_s, nil)
    end

    # Dup the options hash on clone or copy.
    #
    def initialize_copy(other)
      super(other)
      self.options = other.options.dup if other.options
    end

    # Parse the given arguments using the given klass options and this current
    # task options.
    #
    def parse(klass, args)
      raw_options = klass.default_options.merge(self.options || {})
      opts        = Thor::Options.new(raw_options)
      options     = opts.parse(args)
      args        = opts.non_opts

      return args, options
    end

    # Invokes the task name in the given parent with the given args. A task does
    # not invoke private methods and this is the only validation done here.
    #
    def run(instance, args=[])
      raise NoMethodError, "the '#{name}' task of #{instance.class} is private" unless public_method?(instance)
      instance.invoke(name, *args)
    end

    # Get the full options for this task. If a klass is given, the klass default
    # options are merged with the task options.
    #
    def full_options(klass=nil)
      merged_options = if klass && klass.respond_to?(:default_options)
        klass.default_options.merge(options || {})
      else
        options || {}
      end

      Options.new(merged_options)
    end

    # Returns the formatted usage. If a klass is given, the klass default options
    # are merged with the task options providinf a full description.
    #
    # By default it removes the default namespace (TODO is this a good assumption?)
    #
    def formatted_usage(klass=nil, use_namespace=true)
      formatted = ''
      formatted << "#{klass.namespace.gsub(/^default/,'')}:" if klass && use_namespace
      formatted << usage.to_s
      formatted << " #{full_options(klass).formatted_usage}"
      formatted.strip!
      formatted
    end

    protected

      # Given a target, checks if this class name is not a private/protected method.
      #
      def public_method?(instance)
        !(instance.private_methods + instance.protected_methods).include?(name.to_s)
      end

  end
end
