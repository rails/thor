require File.join(File.dirname(__FILE__), 'thor', 'base')

class Thor

  # Invokes a task.
  #
  # ==== Errors
  # Thor::Error:: A Thor error is raised if the user called an undefined task
  #               or called an exisisting task wrongly.
  #
  def invoke(meth, *args)
    super
  rescue ArgumentError => e
    backtrace = sans_backtrace(e.backtrace, caller)

    if backtrace.empty?
      task = self.class[meth]
      raise Error, "'#{meth}' was called incorrectly. Call as '#{task.formatted_usage(self.class)}'"
    else
      raise e
    end
  rescue NoMethodError => e
    if e.message =~ /^undefined method `#{meth}' for #{Regexp.escape(self.inspect)}$/
      raise Error, "The #{self.class.namespace} namespace doesn't have a '#{meth}' task"
    else
      raise e
    end
  end

  # Implement the hooks required by Thor::Base.
  #
  class << self
    protected
      def baseclass
        Thor
      end

      def valid_task?(meth)
        public_instance_methods.include?(meth) && @usage && @desc
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

    # Overwrites option to provide :for functionality. So if you want to redefine
    # an specific option for a previous declared task, you can do:
    #
    #   option :force, :type => :boolean, :default => true, :for => :previous_task
    #
    def option(name, options={})
      scope = if options[:for]
        find_and_refresh_task(options[:for]).options
      else
        method_options
      end

      super(name, options, scope)
    end

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

    # Parse the options given and extract the task to be called from it. If no
    # method can be extracted from args the default task is invoked.
    #
    def start(args=ARGV)
      meth = normalize_task_name(args.shift)
      task = self[meth]
      args, options = task.parse(self, args)
      instance = new(options, *args)
      task.run(instance, args)
    rescue Thor::Error, Thor::Options::Error => e
      $stderr.puts e.message
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

  protected

    # Clean everything that comes from the Thor gempath and remove the caller.
    #
    def sans_backtrace(backtrace, caller)
      dirname = /^#{Regexp.escape(File.dirname(__FILE__))}/
      saned  = backtrace.reject { |frame| frame =~ dirname }
      saned -= caller
    end

end
