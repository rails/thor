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
    def start(args=ARGV)
      if Thor::HELP_MAPPINGS.include?(args.first)
        self.help
      else
        instance, trailing = setup(args)
        all_tasks.values.map { |task| task.run(instance) }
      end
    rescue Thor::Error => e
      $stderr.puts e.message
    end

    # Prints help information.
    #
    # ==== Options
    # short:: When true, shows only usage.
    #
    def help(options={})
      if options[:short]
        print "#{self.namespace} #{self.class_options.map {|_,o| o.usage}.join(' ')}"
        puts
      else
        puts "Usage:"
        puts "  #{self.namespace} #{self.arguments.map{|o| o.usage}.join(' ')}"
        puts

        list = self.class_options.map do |_, option|
          next if option.argument?
          [ option.usage, option.description ]
        end.compact

        unless list.empty?
          puts "Options:"
          Thor::Util.print_list(list)
          puts
        end

        puts self.desc if self.desc
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
