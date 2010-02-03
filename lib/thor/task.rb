class Thor
  class Task < Struct.new(:name, :description, :usage, :options)
    FILE_REGEXP = /^#{Regexp.escape(File.dirname(__FILE__))}/

    # A dynamic task that handles method missing scenarios.
    class Dynamic < Task
      def initialize(name, options=nil)
        super(name.to_s, "A dynamically-generated task", name.to_s, options)
      end

      def run(instance, args=[])
        unless (instance.methods & [name.to_s, name.to_sym]).empty?
          raise Error, "could not find Thor class or task '#{name}'"
        end
        super
      end
    end

    def initialize(name, description, usage, options=nil)
      super(name.to_s, description, usage, options || {})
    end

    def initialize_copy(other) #:nodoc:
      super(other)
      self.options = other.options.dup if other.options
    end

    # By default, a task invokes a method in the thor class. You can change this
    # implementation to create custom tasks.
    def run(instance, args=[])
      raise UndefinedTaskError, "the '#{name}' task of #{instance.class} is private" unless public_method?(instance)
      instance.send(name, *args)
    rescue ArgumentError => e
      raise e if instance.class.respond_to?(:debugging) && instance.class.debugging
      parse_argument_error(instance, e, caller)
    rescue NoMethodError => e
      raise e if instance.class.respond_to?(:debugging) && instance.class.debugging
      parse_no_method_error(instance, e)
    end

    # Returns the formatted usage by injecting given required arguments 
    # and required options into the given usage.
    def formatted_usage(klass, namespace=true)
      namespace = klass.namespace unless namespace == false

      # Add namespace
      formatted = if namespace
        "#{namespace.gsub(/^(default|thor:runner:)/,'')}:"
      else
        ""
      end

      # Add usage with required arguments
      formatted << if klass && !klass.arguments.empty?
        usage.to_s.gsub(/^#{name}/) do |match|
          match << " " << klass.arguments.map{ |a| a.usage }.compact.join(' ')
        end
      else
        usage.to_s
      end

      # Add required options
      formatted << " #{required_options}"

      # Strip and go!
      formatted.strip
    end

    protected

      def required_options
        @required_options ||= options.map{ |_, o| o.usage if o.required? }.compact.sort.join(" ")
      end

      # Given a target, checks if this class name is not a private/protected method.
      def public_method?(instance) #:nodoc:
        collection = instance.private_methods + instance.protected_methods
        (collection & [name.to_s, name.to_sym]).empty?
      end

      def sans_backtrace(backtrace, caller) #:nodoc:
        saned  = backtrace.reject { |frame| frame =~ FILE_REGEXP }
        saned -= caller
      end

      def parse_argument_error(instance, e, caller) #:nodoc:
        backtrace = sans_backtrace(e.backtrace, caller)

        if backtrace.empty? && e.message =~ /wrong number of arguments/
          if instance.is_a?(Thor::Group)
            raise e, "'#{name}' was called incorrectly. Are you sure it has arity equals to 0?"
          else
            raise InvocationError, "'#{name}' was called incorrectly. Call as " <<
                                   "'#{formatted_usage(instance.class)}'"
          end
        else
          raise e
        end
      end

      def parse_no_method_error(instance, e) #:nodoc:
        if e.message =~ /^undefined method `#{name}' for #{Regexp.escape(instance.to_s)}$/
          raise UndefinedTaskError, "The #{instance.class.namespace} namespace " <<
                                    "doesn't have a '#{name}' task"
        else
          raise e
        end
      end

  end
end
