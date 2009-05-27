class Thor
  class Task < Struct.new(:name, :description, :usage, :options)

    # Creates a dynamic task. Dynamic tasks are created on demand to allow method
    # missing calls (since a method missing does not have a task object for it).
    #
    def self.dynamic(name)
      new(name, "A dynamically-generated task", name.to_s, nil)
    end

    # Invokes the task name in the given parent with the given args. It also
    # checks if the method is not private and check if the user invoked the
    # task properly.
    #
    def run(klass, args)
      raise NoMethodError, "the '#{name}' task of #{klass} is private" unless public_method?(klass)

      raw_options = klass.default_options.merge(self.options || {})
      opts        = Thor::Options.new(raw_options)
      options     = opts.parse(args)
      args        = opts.non_opts
      instance    = klass.new(options, *args)

      begin
        instance.invoke(name, *args)
      rescue ArgumentError => e
        backtrace = sans_backtrace(e.backtrace, caller)

        if backtrace.empty?
          raise Error, "'#{name}' was called incorrectly. Call as '#{formatted_usage(klass)}'"
        else
          raise e
        end
      rescue NoMethodError => e
        if e.message =~ /^undefined method `#{name}' for #{Regexp.escape(instance.inspect)}$/
          raise Error, "The #{namespace(klass)} namespace doesn't have a '#{name}' task"
        else
          raise e
        end
      end
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
    def formatted_usage(klass=nil, use_namespace=true)
      formatted = ''
      formatted << "#{namespace(klass)}:" if klass && use_namespace
      formatted << usage.to_s
      formatted << " #{full_options(klass).formatted_usage}"
      formatted.strip!
      formatted
    end

    # Retrieves the namespace for a given class.
    #
    def namespace(klass, remove_default=true)
      Thor::Util.constant_to_thor_path(klass, remove_default)
    end

    protected

      # Given a target, checks if this class name is not a private/protected method.
      #
      def public_method?(klass)
        !(klass.private_instance_methods + klass.protected_instance_methods).include?(name)
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
