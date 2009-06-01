$:.unshift File.expand_path(File.join(File.dirname(__FILE__), '..'))
require 'thor/base'

class Thor::Generator

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

  # Implement the hooks required by Thor::Base.
  #
  class << self
    protected
      def baseclass
        Thor::Generator
      end

      def valid_task?(meth)
        public_instance_methods.include?(meth)
      end

      def create_task(meth)
        tasks[meth.to_s] = Thor::Task.new(meth, nil, nil, nil)
      end
  end

  include Thor::Base

  # Implement specific Thor::Generator logic.
  #
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

    def help
      puts "Usage:"
      puts "  #{self.namespace} #{self.arguments.map{|o| o.usage}.join(' ')}"
      puts
      puts "Options:"
      self.class_options.values.each do |option|
        next if option.argument?
        print "  " + option.usage

        if option.description
          puts " " + option.description
        else
          puts
        end
      end
    end

  end
end
