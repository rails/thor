require File.join(File.dirname(__FILE__), 'thor', 'base')

class Thor
  # Implement the hooks required by Thor::Base.
  #
  class << self
    protected
      def baseclass
        Thor
      end

      def options_scope
        method_options
      end

      def valid_task?(meth)
        public_instance_methods.include?(meth) && @usage
      end

      def create_task(meth)
        tasks[meth.to_s] = Thor::Task.new(meth, @desc, @usage, method_options)
        @usage, @desc, @method_options = nil
      end

      def initialize_added
        default_options.merge!(method_options)
        @method_options = nil
      end
  end

  include Thor::Base

  # Implement specific Thor methods.
  #
  class << self

    # Sets the default task when thor is executed without an explicit task to be called.
    #
    # ==== Parameters
    # meth<Symbol>:: name of the defaut task
    #
    def default_task(meth=nil)
      case meth
        when :none
          @default_task = 'help'
        when nil
          @default_task ||= from_superclass(:default_task, 'help')
        else
          @default_task = meth.to_s
      end
    end

    # Defines the usage and the description of the next task.
    #
    # ==== Parameters
    # usage<String>
    # description<String>
    #
    def desc(usage, description, options={})
      if options[:for]
        task = find_and_refresh_task(options[:for])
        task.usage = usage             if usage
        task.description = description if description
      else
        @usage, @desc = usage, description
      end
    end

    # Maps an input to a task. If you define:
    #
    #   map "-T" => "list"
    #
    # Running:
    #
    #   thor -T
    #
    # Will invoke the list task.
    #
    # ==== Parameters
    # Hash[String|Array => Symbol]:: Maps the string or the string in the array to the given task.
    #
    def map(mappings=nil)
      @map ||= from_superclass(:map, {})

      if mappings
        mappings.each do |key, value|
          if key.respond_to?(:each)
            key.each {|subkey| @map[subkey] = value}
          else
            @map[key] = value
          end
        end
      end

      @map
    end

    # Declares the options for the next task to be declaread.
    #
    # ==== Parameters
    # Hash[Symbol => Symbol]:: The hash key is the name of the option and the value
    # is the type of the option. Can be :optional, :required, :boolean or :numeric.
    #
    def method_options(options=nil)
      @method_options ||= Thor::CoreExt::OrderedHash.new

      if options
        options.each do |key, value|
          @method_options[key] = Thor::Option.parse(key, value)
        end
      end

      @method_options
    end

    # Invokes a specific task. Currently is deprecated you can get the same
    # behavior by retrieving a task with [] and running it:
    #
    #   MyApp[task].run(MyApp, ARGV)
    #
    def invoke(task_name=nil, args=ARGV)
      warn "#{self.name}#invoke is deprecated. You can retrieve an specific task with #{self.name}[] and then run it. Called from: #{caller[0]}"

      args = args.dup
      args.unshift(task_name || default_task)
      start(args)
    end

    protected

      # Receives a task name (can be nil), and try to get a map from it.
      # If a map can't be found use the sent name or the default task.
      #
      def normalize_task_name(meth)
        mapping = map[meth.to_s]
        meth = mapping || meth || default_task
        meth.to_s.gsub('-','_') # treat foo-bar > foo_bar
      end

  end

  map ["-h", "-?", "--help", "-D"] => :help

  desc "help [TASK]", "describe available tasks or one specific task"
  def help(task = nil)
    if task
      task = self.class.tasks[task]
      namespace = task.include?(?:)

      puts task.formatted_usage(self, namespace)
      puts task.description
    else
      puts "Options"
      puts "-------"
      self.class.all_tasks.each do |_, task|
        format = "%-" + (self.class.maxima.usage + self.class.maxima.options + 4).to_s + "s"
        print format % ("#{task.formatted_usage(self, false)}")
        puts  task.description.split("\n").first
      end
    end
  end
end
