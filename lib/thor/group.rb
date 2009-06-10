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

    # Start in Thor::Group works differently. It invokes all tasks inside the class.
    #
    def start(args=ARGV, config={})
      config[:shell] ||= Thor::Base.shell.new

      if Thor::HELP_MAPPINGS.include?(args.first)
        help(config[:shell])
      else
        instance, trailing = setup(args, nil, config)
        all_tasks.values.map { |task| task.run(instance) }
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
        shell.say "#{self.namespace} #{self.class_options.map {|_,o| o.usage}.join(' ')}"
      else
        shell.say "Usage:"
        shell.say "  #{self.namespace} #{self.arguments.map{|o| o.usage}.join(' ')}"
        shell.say

        list = self.class_options.map do |_, option|
          next if option.argument?
          [ option.usage, option.description || '' ]
        end.compact

        unless list.empty?
          shell.say "Options:"
          shell.print_table(list, :emphasize_last => true)
          shell.say
        end

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

  # Invokes a task.
  #
  # ==== Errors
  # ArgumentError:: raised if the arity of the called task is different from 0.
  # NoMethodError:: raised if the method being invoked does not exist.
  #
  def invoke(meth, *args)
    arity = self.method(meth).arity
    raise ArgumentError, "Tasks in Thor::Group must not accept any argument, but #{meth} has arity #{arity}." if arity != 0
    super(meth)
  end

  include Thor::Base
end
