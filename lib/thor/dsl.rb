require 'thor/options'
require 'thor/util'
require 'thor/task'

class Thor

  # Holds class method for Thor class. If you want to create Thor tasks, this
  # is where you should look at.
  #
  module DSL

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
          @default_task ||= (self == Thor ? 'help' : superclass.default_task)
        else
          @default_task = meth.to_s
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
    def map(map={})
      @map ||= from_superclass(:map, {})

      map.each do |key, value|
        if key.respond_to?(:each)
          key.each {|subkey| @map[subkey] = value}
        else
          @map[key] = value
        end
      end

      @map
    end

    # Defines the usage and the description of the next task.
    #
    # ==== Parameters
    # usage<String>
    # description<String>
    #
    def desc(usage, description)
      @usage, @desc = usage, description
    end

    # Defines the group. This is used when thor list is invoked so you can specify
    # that only tasks from a pre-defined group will be shown. Defaults to standard.
    #
    # ==== Parameters
    # name<String|Symbol>
    #
    def group(name)
      @group_name = name.to_s
    end

    # Returns the group name.
    #
    # ==== Returns
    # String
    #
    def group_name
      @group_name ||= from_superclass(:group_name, 'standard')
    end

    # Declares the options for the next task to be declaread.
    #
    # ==== Parameters
    # Hash[Symbol => Symbol]:: The hash key is the name of the option and the value
    # is the type of the option. Can be :optional, :required, :boolean or :numeric.
    #
    def method_options(opts)
      @method_options ||= {}
      @method_options.merge!(opts)
    end

    # Returns the files where the subclasses are maintained.
    #
    # ==== Returns
    # Hash[path<String> => Class]
    #
    def subclass_files
      @subclass_files ||= Hash.new {|h,k| h[k] = []}
    end

    # Returns the subclasses. Subclasses are dynamically added to the array when
    # a class inherits from the Thor class.
    #
    # ==== Returns
    # Array[Class]
    #
    def subclasses
      @subclasses ||= []
    end

    # Returns the tasks for this Thor class.
    #
    # ==== Returns
    # TaskHash:: An ordered hash with this class tasks.
    #
    def tasks
      @tasks ||= from_superclass(:tasks, {}).dup
    end
    alias :all_tasks :tasks

    # A shortcut to retrieve a specific task from this Thor class.
    #
    # ==== Parameters
    # name<Symbol>:: the name of the task to be retrieved
    #
    # ==== Returns
    # Thor::Task
    #
    def [](name)
      tasks[name.to_s]
    end

    # Returns the options for this Thor class. Those option are declared by calling
    # method_options before calling initialize.
    #
    # ==== Returns
    # Hash[Symbol => Symbol]
    #
    def opts
      from_superclass(:opts, {}).merge(@opts || {})
    end

    # Sets the default options for this class. It can be done in two ways:
    #
    # 1) Calling method_options before an initializer
    #
    #   method_options :force => true
    #   def initialize(*args)
    #
    # 2) Calling default_options
    #
    #   default_options :force => true
    #
    # ==== Parameters
    # Hash[Symbol => Symbol]:: The hash has the same syntax as method_options hash.
    #
    def default_options(opts={})
      @opts ||= {}
      @opts.merge!(opts)
    end

    def maxima
      @maxima ||= begin
        max_usage = all_tasks.map {|_, t| t.usage}.max {|x,y| x.to_s.size <=> y.to_s.size}.size
        max_desc  = all_tasks.map {|_, t| t.description}.max {|x,y| x.to_s.size <=> y.to_s.size}.size
        max_opts  = all_tasks.map {|_, t| t.opts ? t.opts(self).formatted_usage : ""}.max {|x,y| x.to_s.size <=> y.to_s.size}.size
        Struct.new(:description, :usage, :opt).new(max_desc, max_usage, max_opts)
      end
    end

    def valid_task?(meth)
      public_instance_methods.include?(meth) && @usage
    end

    def create_task(meth)
      tasks[meth.to_s] = Task.new(@desc, @usage, @method_options)
      @usage, @desc, @method_options = nil
    end

    # Parse the options given and extract the task to be called from it. If no
    # method can be extracted from args the default task is invoked.
    #
    def start(args=ARGV)
      opts    = Thor::Options.new
      options = opts.parse(args, false)
      args    = opts.trailing_non_opts

      meth = args.shift
      meth = @map[meth].to_s if @map && @map[meth]
      meth ||= default_task
      meth = meth.to_s.gsub('-','_') # treat foo-bar > foo_bar

      task = self.tasks[meth]
      options = self.opts || {}
      options.merge!(task.options || {}) if task

      opts = Thor::Options.new(options)
      options = opts.parse(args)
      args    = opts.non_opts

      object = new(options, *args)
      object.options = options
      object.send(meth, *args)
    rescue Thor::Error => e
      $stderr.puts e.message
    end

    # Invokes a specific task. You can use this method instead of start() to
    # to run a thor task if you know the specific task you want to invoke.
    #
    def invoke(task_name=nil, args=ARGV)
      args = args.dup
      args.unshift(task_name || default_task)
      start(args)
    end

    protected

      def from_superclass(method, default=nil)
        self == Thor ? default : superclass.send(method)
      end

  end
end
