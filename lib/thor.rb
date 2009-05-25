$:.unshift File.expand_path(File.dirname(__FILE__))
require 'thor/dsl'

class Thor
  extend Thor::DSL
  attr_accessor :options

  # Main entry point method that should actually invoke the method. You
  # can override this to provide some class-wide processing. The default
  # implementation simply invokes the named method.
  #
  def invoke(meth, *args)
    self.send(meth, *args)
  end

  class << self
    protected
      def inherited(klass)
        register_klass_file(klass)
      end

      def method_added(meth)
        meth = meth.to_s

        if meth == "initialize"
          @opts = @method_options
          @method_options = nil
          return
        end

        return unless valid_task?(meth)
        register_klass_file(self)
        create_task(meth)
      end

      def register_klass_file(klass, file = caller[1].match(/(.*):\d+/)[1])
        subclasses << klass unless subclasses.include?(klass)

        unless self == Thor
          superclass.register_klass_file(klass, file)
          return
        end

        # Subclasses files are tracked just on the superclass, not on subclasses.
        file_subclasses = subclass_files[File.expand_path(file)]
        file_subclasses << klass unless file_subclasses.include?(klass)
      end
  end

  def initialize(opts = {}, *args)
  end

  map ["-h", "-?", "--help", "-D"] => :help

  desc "help [TASK]", "describe available tasks or one specific task"
  def help(task = nil)
    if task
      if task.include? ?:
        task = self.class[task]
        namespace = true
      else
        task = self.class.tasks[task]
      end

      puts task.formatted_usage(namespace)
      puts task.description
    else
      puts "Options"
      puts "-------"
      self.class.tasks.each do |_, task|
        format = "%-" + (self.class.maxima.usage + self.class.maxima.opt + 4).to_s + "s"
        print format % ("#{task.formatted_usage}")
        puts  task.description.split("\n").first
      end
    end
  end
end
