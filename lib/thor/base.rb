require 'thor/options'
require 'thor/util'
require 'thor/task'
require 'thor/core_ext/ordered_hash'

class Thor

  class Maxima < Struct.new(:description, :usage, :options)
  end

  # Holds class method for Thor class. If you want to create Thor tasks, this
  # is where you should look at.
  #
  module Base

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods

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
      def method_options(options)
        @method_options ||= Thor::CoreExt::OrderedHash.new

        if options
          options.each do |key, value|
            @method_options[key] = Thor::Option.parse(key, value)
          end
        end

        @method_options
      end

      # Returns the files where the subclasses are maintained.
      #
      # ==== Returns
      # Hash[path<String> => Class]
      #
      def subclass_files
        @subclass_files ||= Hash.new{ |h,k| h[k] = [] }
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
      # OrderedHash:: An ordered hash with this class tasks.
      #
      def tasks
        @tasks ||= Thor::CoreExt::OrderedHash.new
      end

      # Returns the tasks for this Thor class and all subclasses.
      #
      # ==== Returns
      # OrderedHash
      #
      def all_tasks
        @all_tasks ||= begin
          all = tasks
          all = superclass.all_tasks.merge(tasks) unless self == Thor
          all
        end
      end

      # Retrieve a specific task from this Thor class. If the desired Task cannot
      # be found, returns a dynamic Thor::Task that will map to the given name.
      #
      # ==== Parameters
      # name<Symbol>:: the name of the task to be retrieved
      #
      # ==== Returns
      # Task
      #
      def [](name)
        all_tasks[name.to_s] || Thor::Task.dynamic(name)
      end

      # Returns and sets the default options for this class. It can be done in
      # two ways:
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
      def default_options(options=nil)
        @default_options ||= from_superclass(:default_options, Thor::CoreExt::OrderedHash.new)

        if options
          options.each do |key, value|
            @default_options[key] = Thor::Option.parse(key, value)
          end
        end

        @default_options
      end

      def maxima
        @maxima ||= begin
          compare = lambda { |x,y| x.size <=> y.size }

          max_usage = all_tasks.map{ |_, t| t.usage.to_s }.max(&compare).size
          max_desc  = all_tasks.map{ |_, t| t.description.to_s }.max(&compare).size
          max_opts  = all_tasks.map{ |_, t| t.full_options(self).formatted_usage }.max(&compare).size

          Thor::Maxima.new(max_desc, max_usage, max_opts)
        end
      end

      def valid_task?(meth)
        public_instance_methods.include?(meth) && @usage
      end

      def create_task(meth)
        tasks[meth.to_s] = Task.new(meth, @desc, @usage, @method_options)
        @usage, @desc, @method_options = nil
      end

      # Parse the options given and extract the task to be called from it. If no
      # method can be extracted from args the default task is invoked.
      #
      def start(args=ARGV)
        meth = normalize_task_name(args.shift)
        self[meth].run(self, args)
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
          self == Thor ? default : superclass.send(method).dup
        end

        # Receives a task name (can be nil), and try to get a map from it.
        # If a map can't be found use the sent name or the default task.
        #
        def normalize_task_name(meth)
          mapping = map[meth.to_s]
          meth = mapping || meth || default_task
          meth.to_s.gsub('-','_') # treat foo-bar > foo_bar
        end

        def inherited(klass)
          register_klass_file(klass)
        end

        def method_added(meth)
          meth = meth.to_s

          if meth == "initialize"
            default_options.merge!(@method_options)
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

    # Main entry point method that should actually invoke the method. You
    # can override this to provide some class-wide processing. The default
    # implementation simply invokes the named method.
    #
    def invoke(meth, *args)
      self.send(meth, *args)
    end

    def initialize(options={}, *args)
      @options = options
    end

  end
end
