require File.join(File.dirname(__FILE__), 'base')

class Thor::Generator
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

    # Adds an argument (a required option) to the generator and creates an
    # attribute acessor for it.
    #
    # ==== Parameters
    # name<Symbol>:: The name of the argument.
    # options<Hash>:: The description, type and aliases for this option.
    #                 The type can be :string, :boolean, :numeric, :hash or :array. If none is given
    #                 a default type which accepts both (--name and --name=NAME) entries is assumed.
    #
    def argument(name, options={})
      attr_accessor name
      default_options[name] = Thor::Option.new(name, options[:description], true, options[:type],
                                               nil, options[:aliases])
    end

    # Overwrite option method to tell it to which hash it should add the new
    # option.
    #
    def option(name, options={})
      super(name, options, default_options)
    end

    # Start in generators works differently. It invokes all tasks inside the class.
    #
    def start(args=ARGV)
      opts    = Thor::Options.new
      options = opts.parse(args)
      args    = opts.non_opts

      instance = new(options, *args)

      all_tasks.values.map { |task| instance.send(task.name, *args) }
    rescue Thor::Error => e
      $stderr.puts e.message
    end

  end
end
