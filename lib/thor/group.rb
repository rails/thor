class Thor::Group

  class << self

    # The descrition for this Thor::Group. If none is provided, but a source root
    # exists, tries to find the USAGE one folder above it, otherwise searches
    # in the superclass.
    #
    # ==== Parameters
    # description<String>:: The description for this Thor::Group.
    #
    def desc(description=nil)
      case description
        when nil
          @desc ||= from_superclass(:desc, nil)
        else
          @desc = description
      end
    end

    # Implements the prepare interface being used by start.
    #
    def prepare(task, args, config) #:nodoc:
      split_args, split_opts = Thor::Options.split(args)

      instance = new(split_args, split_opts, config)

      return instance, nil
    end

    # Prints help information.
    #
    # ==== Options
    # short:: When true, shows only usage.
    #
    def help(shell, options={})
      if options[:short]
        shell.say banner
      else
        shell.say "Usage:"
        shell.say "  #{banner}"
        shell.say
        class_options_help(shell)
        shell.say self.desc if self.desc
      end
    end

    protected

      # The banner for this class. You can customize it if you are invoking the
      # thor class by another means which is not the Thor::Runner.
      #
      def banner #:nodoc:
        "#{self.namespace} #{self.arguments.map {|o| o.usage }.join(' ')}"
      end

      def baseclass #:nodoc:
        Thor::Group
      end

      def valid_task?(meth) #:nodoc:
        public_instance_methods.include?(meth)
      end

      def create_task(meth) #:nodoc:
        tasks[meth.to_s] = Thor::Task.new(meth, nil, nil, nil)
      end

      def normalize_arguments(args, config) #:nodoc:
        if Thor::HELP_MAPPINGS.include?(args.first)
          help(config[:shell])
          nil
        else
          :all
        end
      end
  end

  include Thor::Base

  protected

    # Overwrite _setup_for_invoke to force invocation of all tasks when :all is
    # supplied.
    #
    def _setup_for_invoke(object, task=nil)
      super(object.to_s == "all" ? nil : object)
    end

end
