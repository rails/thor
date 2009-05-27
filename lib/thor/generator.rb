require 'thor'

class Thor::Generator < Thor
  class << self

    undef_method :default_task, :map, :method_options

    # Start in generators works differently. It invokes all tasks inside the class.
    #
    def start(args=ARGV)
      opts    = Thor::Options.new
      options = opts.parse(args, false)
      args    = opts.trailing_non_opts

      tasks     = self.all_tasks.values.reject { |task| task.name == 'help' }
      tasks.map { |task| task.run(self, args) }
    rescue Thor::Error => e
      $stderr.puts e.message
    end

    def valid_task?(meth)
      public_instance_methods.include?(meth)
    end

    def create_task(meth)
      tasks[meth.to_s] = Thor::Task.new(meth.to_s, @desc, @usage, @method_options)
    end

    protected

      def from_superclass(method, default=nil)
        self == Thor::Generator ? default : superclass.send(method)
      end

  end
end
