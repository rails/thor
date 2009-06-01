require 'thor/core_ext/ordered_hash'
require 'thor/error'
require 'thor/option'
require 'thor/options'
require 'thor/task'
require 'thor/util'

class Thor
  HELP_MAPPINGS = ["-h", "-?", "--help", "-D"]

  class Maxima < Struct.new(:description, :usage, :options)
  end

  module Base

    def self.included(base)
      base.extend ClassMethods
    end

    def self.register_klass_file(klass)
      file = caller[1].match(/(.*):\d+/)[1]
      Thor::Base.subclasses << klass unless Thor::Base.subclasses.include?(klass)

      file_subclasses = Thor::Base.subclass_files[File.expand_path(file)]
      file_subclasses << klass unless file_subclasses.include?(klass)
    end

    # Returns the classes that inherits from Thor or Thor::Generator.
    #
    # ==== Returns
    # Array[Class]
    #
    def self.subclasses
      @subclasses ||= []
    end

    # Returns the files where the subclasses are kept.
    #
    # ==== Returns
    # Hash[path<String> => Class]
    #
    def self.subclass_files
      @subclass_files ||= Hash.new{ |h,k| h[k] = [] }
    end

    attr_accessor :options

    def initialize(options={}, *args)
      self.options = options
    end

    # Main entry point method that actually invoke the task. Currently
    # overwritten both by Thor and Thor::Generator.
    #
    def invoke(meth, *args)
      self.send(meth, *args)
    end

    module ClassMethods

      # Adds an argument to the class and creates an attr_accessor for it.
      #
      # The difference between arguments and options are how they are parsed
      # from the command line. Arguments can be retrieved in two ways:
      #
      #   thor task NAME
      #
      # Or:
      #
      #   thor task --name=NAME
      #
      # While options are only retrieved in the second way, doesn't matter if they
      # are required or not. Besides, arguments cannot have type :default or :boolean.
      #
      # Finally, arguments can be optional (supplying :optional => :true or
      # :required => false), but you cannot have a required argument after a
      # non-required argument. If you try it, an error is raised.
      #
      # ==== Parameters
      # name<Symbol>:: The name of the argument.
      # options<Hash>:: The description, type, default value and aliases for this argument.
      #                 The type can be :string, :numeric, :hash or :array. If none, string is assumed.
      #
      # ==== Errors
      # ArgumentError:: Raised if you supply a required argument after a non required one.
      #
      def argument(name, options={})
        no_tasks { attr_accessor name }

        required = if options.key?(:optional)
          !options[:optional]
        elsif options.key?(:required)
          options[:required]
        else
          options[:default].nil?
        end

        class_options.values.each do |option|
          next unless option.argument? && !option.required?
          raise ArgumentError, "You cannot have #{name.to_s.inspect} as required argument after " <<
                               "the non-required argument #{option.human_name.inspect}."
        end if required

        class_options[name] = Thor::Argument.new(name, options[:description], required,
                                                 options[:type], options[:default], options[:aliases])
      end

      # Adds a bunch of options to the set of class options.
      #
      #   class_options :foo => :optional, :bar => :required, :baz => :string
      #
      # If you prefer more detailed declaration, check class_option.
      #
      # ==== Parameters
      # Hash[Symbol => Object]
      #
      def class_options(options=nil)
        @class_options ||= from_superclass(:class_options, Thor::CoreExt::OrderedHash.new)
        build_options(options, @class_options) if options
        @class_options
      end

      # Adds an option to the set of class options
      #
      # ==== Parameters
      # name<Symbol>:: The name of the argument.
      # options<Hash>:: The description, type, default value, aliases and if this option is required or not.
      #                 The type can be :string, :boolean, :numeric, :hash or :array. If none is given
      #                 a default type which accepts both (--name and --name=NAME) entries is assumed.
      #
      def class_option(name, options)
        build_option(name, options, class_options)
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

      # Retrieves the namespace for this class.
      #
      def namespace
        Thor::Util.constant_to_namespace(self, false)
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

        # Setup this thor class using the given arguments and extra options. This
        # holds the initialization process common to all Thor classes.
        #
        def setup(args, extra_options=nil)
          options = self.class_options
          options = options.merge(extra_options) if extra_options

          opts = Thor::Options.new(options)
          opts.parse(args)

          instance = new(opts.options)
          opts.arguments.each do |key, value|
            instance.send(:"#{key}=", value)
          end

          return instance, opts.trailing
        end

        # Build an option and adds it to the given scope.
        #
        # ==== Parameters
        # name<Symbol>:: The name of the argument.
        # options<Hash>:: The description, type, default value and aliases for this option.
        #                 The type can be :string, :boolean, :numeric, :hash or :array. If none is given
        #                 a default type which accepts both (--name and --name=NAME) entries is assumed.
        #
        def build_option(name, options, scope)
          scope[name] = Thor::Option.new(name, options[:description], options[:required], options[:type],
                                         options[:default], options[:aliases])
        end

        # Receives a hash of options, parse them and add to the scope. This is a
        # fast way to set a bunch of options:
        #
        #   build_options :foo => :optional, :bar => :required, :baz => :string
        #
        # ==== Parameters
        # Hash[Symbol => Object]
        #
        def build_options(options, scope)
          options.each do |key, value|
            scope[key] = Thor::Option.parse(key, value)
          end
        end

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
          Thor::Base.register_klass_file(klass)
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
          Thor::Base.register_klass_file(self)
          create_task(meth)
        end

        def from_superclass(method, default=nil)
          self == baseclass ? default : superclass.send(method).dup
        end

        # SIGNATURE: Sets the baseclass. This is where the superclass lookup
        # finishes.
        def baseclass #:nodoc:
        end

        # SIGNATURE: Defines if a given method is a valid_task?. This method is
        # called before a new method is added to the class.
        def valid_task?(meth) #:nodoc:
        end

        # SIGNATURE: Creates a new task if valid_task? is true. This method is
        # called when a new method is added to the class.
        def create_task(meth) #:nodoc:
        end

        # SIGNATURE: Defines behavior when the initialize method is added to the
        # class.
        def initialize_added #:nodoc:
        end

    end

  end
end
