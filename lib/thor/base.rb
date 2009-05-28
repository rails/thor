$:.unshift File.expand_path(File.join(File.dirname(__FILE__), '..'))

require 'thor/core_ext/ordered_hash'
require 'thor/error'
require 'thor/option'
require 'thor/options'
require 'thor/task'
require 'thor/util'

class Thor

  class Maxima < Struct.new(:description, :usage, :options)
  end

  module Base

    def self.included(base)
      base.extend ClassMethods
    end

    attr_accessor :options

    def initialize(options={}, *args)
      self.options = options
    end

    # Main entry point method that actually invoke the task.
    #
    def invoke(meth, *args)
      self.send(meth, *args)
    end

    module ClassMethods

      # Adds an option (which is not required). In Thor classes it adds an option
      # to the next task declaread. On Thor::Generator it adds an option generator
      # wise (since generators does not have method wise options).
      #
      # ==== Parameters
      # name<Symbol>:: The name of the argument.
      # options<Hash>:: The description, type, default value and aliases for this option.
      #                 The type can be :string, :boolean, :numeric, :hash or :array. If none is given
      #                 a default type which accepts both (--name and --name=NAME) entries is assumed.
      #
      def option(name, options={}, scope=nil)
        scope[name] = Thor::Option.new(name, options[:description], false, options[:type],
                                       options[:default], options[:aliases])
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
        @all_tasks ||= from_superclass(:all_tasks, Thor::CoreExt::OrderedHash.new)
        @all_tasks.merge(tasks)
      end

      # Remove a given task from this Thor class. This is usually done if you 
      # are inheriting from another class and don't want it to be available
      # anymore.
      #
      # By default it only remove the mapping to the task. But you can supply
      # :undefine => true to undefine the method from the class as well.
      #
      # ==== Parameters
      # name<Symbol|String>:: The name of the task to be removed
      # options<Hash>:: You can give :undefine => true if you want tasks the method
      #                 to be undefined from the class as well.
      #
      def remove_task(*names)
        options = names.last.is_a?(Hash) ? names.pop : {}

        names.each do |name|
          tasks.delete(name.to_s)
          all_tasks.delete(name.to_s)
          undef_method name if options[:undefine]
        end
      end

      # Retrieve a specific task from this Thor class. If the desired Task cannot
      # be found, returns a dynamic Thor::Task that will map to the given method.
      #
      # ==== Parameters
      # meth<Symbol>:: the name of the task to be retrieved
      #
      # ==== Returns
      # Task
      #
      def [](meth)
        all_tasks[meth.to_s] || Thor::Task.dynamic(meth)
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

      # Returns the maxima for this Thor class and all subclasses
      #
      # ==== Returns
      # maxima<Struct @description @usage @options>
      #
      def maxima
        @maxima ||= begin
          compare = lambda { |x,y| x.size <=> y.size }

          max_usage = all_tasks.map{ |_, t| t.usage.to_s }.max(&compare).size
          max_desc  = all_tasks.map{ |_, t| t.description.to_s }.max(&compare).size
          max_opts  = all_tasks.map{ |_, t| t.full_options(self).formatted_usage }.max(&compare).size

          Thor::Maxima.new(max_desc, max_usage, max_opts)
        end
      end

      # All methods defined inside the given block are not added as tasks.
      #
      # So you can do:
      #
      #   class MyScript < Thor
      #     no_tasks do
      #       def this_is_not_a_task
      #       end
      #     end
      #   end
      #
      # You can also add the method and remove it from the task list:
      #
      #   class MyScript < Thor
      #     def this_is_not_a_task
      #     end
      #     remove_task :this_is_not_a_task
      #   end
      #
      def no_tasks
        @no_tasks = true
        yield
        @no_tasks = false
      end

      # Invokes a specific task. You can use this method instead of start() to
      # to run a thor task if you know the specific task you want to invoke.
      #
      def invoke(task_name, args=ARGV)
        args = args.dup
        args.unshift(task_name)
        start(args)
      end

      protected

        # Finds a task with the given name. If the task belongs to the current
        # class, just return it, otherwise dup it and add the fresh copy to the
        # current task hash.
        #
        def find_and_refresh_task(name)
          task = if task = tasks[name.to_s]
            task
          elsif task = all_tasks[name.to_s]
            tasks[name.to_s] = task.clone
          else
            raise ArgumentError, "You supplied :for => #{name.inspect}, but the task #{name.inspect} could not be found."
          end
        end

        # Everytime someone inherits from a Thor class, register the klass
        # and file into baseclass.
        #
        def inherited(klass)
          register_klass_file(klass)
        end

        # Fire this callback whenever a method is added. Added methods are
        # tracked as tasks if the requirements set by valid_task? are valid.
        #
        def method_added(meth)
          meth = meth.to_s

          if meth == "initialize"
            initialize_added
            return
          end

          return if @no_tasks || !valid_task?(meth)
          register_klass_file(self)
          create_task(meth)
        end

        # Register the klass file by tracking the class in the base class and
        # the file where the class was defined.
        #
        def register_klass_file(klass, file=caller[1].match(/(.*):\d+/)[1])
          subclasses << klass unless subclasses.include?(klass)

          unless self == baseclass
            superclass.register_klass_file(klass, file)
            return
          end

          file_subclasses = subclass_files[File.expand_path(file)]
          file_subclasses << klass unless file_subclasses.include?(klass)
        end

        def from_superclass(method, default=nil)
          self == baseclass ? default : superclass.send(method).dup
        end

        # SIGNATURE: Sets the baseclass to Thor. This is where the superclass
        # lookup finishes.
        def baseclass #:nodoc:
        end

        # SIGNATURE: Defines if a given method is a valid_task?. This method is
        # called everytime a new method is added to the class.
        def valid_task?(meth) #:nodoc:
        end

        # SIGNATURE: Creates a new task if valid_task? is true. This method is
        # called everytime a new method is added to the class.
        def create_task(meth) #:nodoc:
        end

        # SIGNATURE: Defines behavior when the initialize method is added to the
        # class.
        def initialize_added #:nodoc:
        end

    end

  end
end
