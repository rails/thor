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

    # Sets the condition for some task to be executed in the class level. Why
    # is this important? Setting the conditions in the class level allows to
    # an inherited class change the conditions and customize the Thor::Group as
    # it wishes.
    #
    # The conditions given are retrieved from the options hash. Let's suppose
    # that a task is only executed if --test-framework is rspec. You could do
    # this:
    #
    #   class_option :test_framework, :type => :string
    #
    #   conditions :test_framework => :rspec
    #   def create_rspec_files
    #     # magic
    #   end
    #
    # Later someone creates a framework on top of rspec and need rspec files to
    # generated as well. He could then change the conditions:
    #
    #   conditions :test_framework => [ :rspec, :remarkable ], :for => :create_rspec_files
    #
    # He could also use remove_conditions and remove previous set conditions:
    #
    #   remove_conditions :test_framework, :for => :create_rspec_files
    #
    # Conditions only work with the class option to be comparead to is a boolean,
    # string or numeric (no array or hash comparisions).
    #
    # ==== Parameters
    # conditions<Hash>:: the conditions for the task. The key is the option name
    #                    and the value is the condition to be checked. If the
    #                    condition is an array, it checkes if the current value
    #                    is included in the array. If a regexp, checks if the
    #                    value matches, all other values are simply compared (==).
    #
    def conditions(conditions=nil)
      subject = if conditions && conditions[:for]
        find_and_refresh_task(options[:for]).conditions
      else
        @conditions ||= {}
      end

      subject.merge!(conditions) if conditions
      subject
    end

    # Remove a previous specified condition. Check <tt>conditions</tt> above for
    # a complete example.
    #
    # ==== Parameters
    # conditions<Array>:: An array of conditions to be removed.
    # for<Hash>:: A hash with :for as key indicating the task to remove the conditions from.
    #
    # ==== Examples
    #
    #   remove_conditions :test_framework, :orm, :for => :create_app_skeleton
    #
    def remove_conditions(*conditions)
      subject = find_and_refresh_task(conditions.pop[:for]).conditions
      conditions.each do |condition|
        subject.delete(condition)
      end
      subject
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
        tasks[meth.to_s] = Thor::Task.new(meth, nil, nil, nil, @conditions)
        @conditions = nil
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
