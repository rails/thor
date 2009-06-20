class Thor::Group

  class << self

    # The descrition for this Thor::Group. If none is provided, but a source root
    # exists and we have an USAGE inside, this file is used as description. This
    # is good because we will load such files only when we need it.
    #
    # ==== Parameters
    # description<String>:: The description for this Thor::Group.
    #
    def desc(description=nil)
      case description
        when nil
          @desc ||= if respond_to?(:source_root) && File.exist?(File.join(source_root, "USAGE"))
            File.read(File.join(source_root, "USAGE"))
          else
            from_superclass(:desc, nil)
          end
        else
          @desc = description
      end
    end

    # Start in Thor::Group works differently. It invokes all tasks inside the
    # class and does not have to parse task options.
    #
    def start(args=ARGV, config={})
      config[:shell] ||= Thor::Base.shell.new

      if Thor::HELP_MAPPINGS.include?(args.first)
        help(config[:shell])
      else
        opts = Thor::Options.new(class_options)
        opts.parse(args)

        new(opts.arguments, opts.options, config).invoke(:all)
      end
    rescue Thor::Error => e
      config[:shell].error e.message
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
  end

  include Thor::Base

  protected

    # Overwrite _setup_for_invoke to force invocation of all tasks when :all is
    # supplied.
    #
    def _setup_for_invoke(name, method_args, options)
      name = nil if name.to_s == "all"
      super(name, method_args, options)
    end

end
