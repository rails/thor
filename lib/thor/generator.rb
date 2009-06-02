$:.unshift File.expand_path(File.join(File.dirname(__FILE__), '..'))
require 'thor/base'

class Thor::Generator

  class << self

    # Start in generators works differently. It invokes all tasks inside the class.
    #
    def start(args=ARGV)
      if Thor::HELP_MAPPINGS.include?(args.first)
        self.help
      else
        instance, trailing = setup(args)
        all_tasks.values.map { |task| task.run(instance) }
      end
    rescue Thor::Error, Thor::Options::Error => e
      $stderr.puts e.message
    end

    # Prints help information about this generator.
    #
    # ==== Options
    # short:: When true, shows only usage.
    #
    def help(options={})
      if options[:short]
        print "#{self.namespace} #{self.class_options.map {|_,o| o.usage}.join(' ')}"
        # print self.description.split("\n").first if self.description
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

        # puts self.description
      end
    end

    protected

      def baseclass #:nodoc:
        Thor::Generator
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
    raise ArgumentError, "Tasks in generators must not accept any argument, but #{meth} has arity #{arity}." if arity != 0
    super(meth)
  end

  include Thor::Base
end
