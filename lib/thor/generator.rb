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

      generator = new(options, *args)
      tasks     = self.all_tasks.values.reject { |task| task.meth == 'help' }
      tasks.map { |task| task.parse(generator, args) }
    rescue Thor::Error => e
      $stderr.puts e.message
    end

    def valid_task?(meth)
      public_instance_methods.include?(meth)
    end

    def create_task(meth)
      tasks[meth] = Thor::Task.new(meth, @desc, @usage, @method_options)
    end

  end
end
