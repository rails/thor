require 'thor'

class Thor::Generator
  include Thor::Base

  class << self
    undef_method :default_task, :map, :method_options

    # Sets the baseclass to Thor. This is where the tasks lookup finishes.
    #
    def baseclass
      Thor::Generator
    end

    # Start in generators works differently. It invokes all tasks inside the class.
    #
    def start(args=ARGV)
      opts    = Thor::Options.new
      options = opts.parse(args, false)
      args    = opts.trailing_non_opts

      all_tasks.values.map { |task| task.run(self, args) }
    rescue Thor::Error => e
      $stderr.puts e.message
    end

    def valid_task?(meth)
      public_instance_methods.include?(meth)
    end

    def create_task(meth)
      tasks[meth.to_s] = Thor::Task.new(meth.to_s, nil, nil, nil)
    end

  end
end
