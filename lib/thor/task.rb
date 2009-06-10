class Thor
  class Task < Struct.new(:name, :description, :usage, :options)

    # Creates a dynamic task. Dynamic tasks are created on demand to allow method
    # missing calls (since a method missing does not have a task object for it).
    #
    def self.dynamic(name)
      new(name, "A dynamically-generated task", name.to_s, nil)
    end

    def initialize(name, description, usage, options)
      super(name, description, usage, options || {})
    end

    # Dup the options hash on clone.
    #
    def initialize_copy(other)
      super(other)
      self.options = other.options.dup if other.options
    end

    # By default, a task invokes a method in the thor class. You can change this
    # implementation to create custom tasks.
    #
    def run(instance, *args)
      raise UndefinedTaskError, "the '#{name}' task of #{instance.class} is private" unless public_method?(instance)
      instance.send(name, *args)
    rescue ArgumentError => e
      backtrace = sans_backtrace(e.backtrace, caller)

      if instance.is_a?(Thor) && backtrace.empty?
        raise InvocationError, "'#{name}' was called incorrectly. Call as '#{formatted_usage(instance.class)}'"
      else
        raise e
      end
    rescue NoMethodError => e
      if e.message =~ /^undefined method `#{name}' for #{Regexp.escape(instance.to_s)}$/
        raise UndefinedTaskError, "The #{instance.class.namespace} namespace doesn't have a '#{name}' task"
      else
        raise e
      end
    end

    # Returns the first line of the given description.
    #
    def short_description
      description.split("\n").first if description
    end

    # Returns the formatted usage. If a klass is given, the klass default options
    # are merged with the task options providinf a full description.
    #
    def formatted_usage(klass=nil)
      formatted = ''
      formatted << "#{klass.namespace.gsub(/^default/,'')}:" if klass
      formatted << usage.to_s
      formatted << " #{formatted_options}"
      formatted.strip!
      formatted
    end

    # Returns the options usage for this task.
    #
    def formatted_options
      @formatted_options ||= options.values.sort.map{ |o| o.usage }.join(" ")
    end

    protected

      # Given a target, checks if this class name is not a private/protected method.
      #
      def public_method?(instance)
        !(instance.private_methods + instance.protected_methods).include?(name.to_s)
      end

      # Clean everything that comes from the Thor gempath and remove the caller.
      #
      def sans_backtrace(backtrace, caller)
        dirname = /^#{Regexp.escape(File.dirname(__FILE__))}/
        saned  = backtrace.reject { |frame| frame =~ dirname }
        saned -= caller
      end

  end
end
