class Thor::Group

  class << self

    # The descrition for this Thor::Group as a whole.
    #
    # ==== Parameters
    # description<String>:: The description for this Thor::Group.
    #
    def desc(description=nil)
      case description
        # TODO When a symbol is given, read a file in the current directory
        # when Symbol
        #   @desc = File.read
        when nil
          @desc ||= from_superclass(:desc, nil)
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

        new(opts.arguments, opts.options, config).invoke_all
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
        shell.say "#{self.namespace} #{self.arguments.map {|o| o.usage }.join(' ')}"
      else
        shell.say "Usage:"
        shell.say "  #{self.namespace} #{self.arguments.map {|o| o.usage }.join(' ')}"
        shell.say
        class_options_help(shell)
        shell.say self.desc if self.desc
      end
    end

    protected

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

  # Invokes all tasks in the instance.
  #
  def invoke_all
    self.class.all_tasks.map { |_, task| task.run(self) }
  end

  include Thor::Base
end
