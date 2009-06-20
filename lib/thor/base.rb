require 'thor/core_ext/hash_with_indifferent_access'
require 'thor/core_ext/ordered_hash'
require 'thor/shell/basic'
require 'thor/error'
require 'thor/options'
require 'thor/task'
require 'thor/util'

class Thor
  HELP_MAPPINGS       = %w(-h -? --help -D)
  RESERVED_TASK_NAMES = %w(all invoke shell behavior root destination_root relative_root source_root)

  class Maxima < Struct.new(:usage, :options, :class_options)
  end

  module Base

    def self.included(base) #:nodoc:
      base.send :extend,  ClassMethods
      base.send :include, SingletonMethods
    end

    # Returns the classes that inherits from Thor or Thor::Group.
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

    # Returns the shell used in all Thor classes.
    #
    def self.shell
      @shell || Thor::Shell::Basic
    end

    # Sets the shell used in all Thor classes.
    #
    def self.shell=(klass)
      @shell = klass
    end

    # Whenever a class inherits from Thor or Thor::Group, we should track the
    # class and the file on Thor::Base. This is the method responsable for it.
    #
    def self.register_klass_file(klass) #:nodoc:
      file = caller[1].match(/(.*):\d+/)[1]
      Thor::Base.subclasses << klass unless Thor::Base.subclasses.include?(klass)

      file_subclasses = Thor::Base.subclass_files[File.expand_path(file)]
      file_subclasses << klass unless file_subclasses.include?(klass)
    end

    module ClassMethods
      # Adds an argument to the class and creates an attr_accessor for it.
      #
      # Arguments are different from options in several aspects. The first one
      # is how they are parsed from the command line, arguments are retrieved
      # from position:
      #
      #   thor task NAME
      #
      # Instead of:
      #
      #   thor task --name=NAME
      #
      # Besides, arguments are used inside your code as an accessor (self.argument),
      # while options are all kept in a hash (self.options).
      #
      # Finally, arguments cannot have type :default or :boolean but can be
      # optional (supplying :optional => :true or :required => false), although
      # you cannot have a required argument after a non-required argument. If you
      # try it, an error is raised.
      #
      # ==== Parameters
      # name<Symbol>:: The name of the argument.
      # options<Hash>:: Described below.
      #
      # ==== Options
      # :desc     - Description for the argument.
      # :required - If the argument is required or not.
      # :optional - If the argument is optional or not.
      # :type     - The type of the argument, can be :string, :hash, :array, :numeric.
      # :default  - Default value for this argument. It cannot be required and have default values.
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

        class_options[name] = Thor::Argument.new(name, options[:desc], required,
                                                 options[:type], options[:default])
      end

      # Returns this class arguments, looking up in the ancestors chain.
      #
      # ==== Returns
      # Array[Thor::Argument]
      #
      def arguments
        class_options.values.select{ |o| o.argument? }
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
      # options<Hash>:: Described below.
      #
      # ==== Options
      # :desc     - Description for the argument.
      # :required - If the argument is required or not.
      # :default  - Default value for this argument. It cannot be required and have default values.
      # :group    - The group for this options. Use by class options to output options in different levels.
      # :aliases  - Aliases for this option.
      # :type     - The type of the argument, can be :string, :hash, :array, :numeric, :boolean or :default.
      #             Default accepts arguments as booleans (--switch) or as strings (--switch=VALUE).
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
      def group(name=nil)
        case name
          when nil
            @group ||= from_superclass(:group, 'standard')
          else
            @group = name.to_s
        end
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

      # Removes a given task from this Thor class. This is usually done if you
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

      # Sets the namespace for the Thor or Thor::Group class. By default the
      # namespace is retrieved from the class name. If your Thor class is named
      # Scripts::MyScript, the help method, for example, will be called as:
      #
      #   thor scripts:my_script -h
      #
      # If you change the namespace:
      #
      #   namespace :my_scripts
      #
      # You change how your tasks are invoked:
      #
      #   thor my_scripts -h
      #
      # Finally, if you change your namespace to default:
      #
      #   namespace :default
      #
      # Your tasks can be invoked with a shortcut. Instead of:
      #
      #   thor :my_task
      #
      def namespace(name=nil)
        case name
          when nil
            @namespace ||= Thor::Util.constant_to_namespace(self, false)
          else
            @namespace = name.to_s
        end
      end

      protected

        # Prints the class optins per group. If a class options does not belong
        # to any group, it's grouped as "Class options" in Thor classes and as
        # "Options" in Thor::Group (since Thor::Group does not have method
        # options, there is not need to add "Class" frist).
        #
        def class_options_help(shell, ungrouped_name=nil) #:nodoc:
          unless self.class_options.empty?
            groups = self.class_options.group_values_by { |o| o.group }

            printer = lambda do |group_name, options|
              unless options.empty?
                list = []

                options.each do |option|
                  next if option.argument?

                  list << [ option.usage(false), option.description || "" ]
                  list << [ "", "Default: #{option.default}" ] if option.description && option.default
                end

                if group_name
                  shell.say "#{group_name} options:"
                else
                  shell.say "Options:"
                end

                shell.print_table(list, :emphasize_last => true, :ident => 2)
                shell.say ""
              end
            end

            # Deal with default group
            global_options = groups.delete(nil)
            printer.call(ungrouped_name, global_options) if global_options

            # Print all others
            groups.each(&printer)
          end
        end

        # Build an option and adds it to the given scope.
        #
        # ==== Parameters
        # name<Symbol>:: The name of the argument.
        # options<Hash>:: Described in both class_option and method_option.
        #
        def build_option(name, options, scope)
          scope[name] = Thor::Option.new(name, options[:desc], options[:required], options[:type],
                                               options[:default], options[:aliases], options[:group])
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

          if RESERVED_TASK_NAMES.include?(meth)
            raise ScriptError, "'#{meth}' is a Thor reserved word and cannot be defined as task"
          end

          Thor::Base.register_klass_file(self)
          create_task(meth)
        end

        def from_superclass(method, default=nil)
          if self == baseclass
            default
          else
            value = superclass.send(method)
            value.dup if value
          end
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

    module SingletonMethods
      attr_accessor :options

      SHELL_DELEGATED_METHODS = [:ask, :yes?, :no?, :say, :say_status, :print_list, :print_table]

      # It receives arguments in an Array and two hashes, one for options and
      # other for configuration.
      #
      # Notice that it does not check arguments type neither if all required
      # arguments were supplied. It should be done by the parser.
      #
      # ==== Parameters
      # args<Array[Object]>:: An array of objects. The objects are applied to their
      #                       respective accessors declared with <tt>argument</tt>.
      #
      # options<Hash>:: An options hash that will be available as self.options.
      #                 The hash given is converted to a hash with indifferent
      #                 access, magic predicates (options.skip?) and then frozen.
      #
      # config<Hash>:: Configuration for this Thor class.
      #
      # ==== Configuration
      # shell<Object>:: An instance of the shell to be used.
      #
      # ==== Examples
      #
      #   class MyScript < Thor
      #     argument :first, :type => :numeric
      #   end
      #
      #   MyScript.new [1.0], { :foo => :bar }, :shell => Thor::Shell::Basic.new
      #
      def initialize(args=[], options={}, config={})
        self.class.arguments.zip(args).each do |argument, value|
          send("#{argument.human_name}=", value)
        end

        self.options = Thor::CoreExt::HashWithIndifferentAccess.new(options).freeze

        # Configure shell and set base if not already
        self.shell = config[:shell]
        self.shell.base ||= self if self.shell.respond_to?(:base)
      end

      # Holds the shell for the given Thor instance. If no shell is given,
      # it gets a default shell from Thor::Base.shell.
      #
      def shell
        @shell ||= Thor::Base.shell.new
      end

      # Sets the shell for this thor class.
      #
      def shell=(shell)
        @shell = shell
      end

      # Receives a name and invokes it. The name can be either a namespaced name,
      # a current class task or even a class. Arguments are given in an array and
      # options given are merged with the invoker options.
      #
      # ==== Examples
      #
      #   class A < Thor
      #     def foo
      #       invoke :bar
      #       invoke "b:lib", ["merb", "rails"]
      #     end
      #
      #     def bar
      #       invoke "b:lib", ["merb", "rails"]
      #       # magic
      #     end
      #   end
      #
      #   class B < Thor
      #     argument :preferred_framework, :type => :string
      #
      #     def lib(second_framework)
      #       # magic
      #     end
      #   end
      #
      # You can notice that the method "foo" above invokes two tasks: "bar",
      # which belongs to the same class and "lib" that belongs to the class B.
      #
      # By using an invocation system you ensure that a task is invoked only once.
      # In the example above, invoking foo will invoke "b:lib" just once, even if
      # it's invoked later by "bar" method.
      #
      # When invoking another class, there are a few things to keep in mind:
      #
      #   1) Class arguments are parsed first. In the example above, preferred
      #      framework is going to consume "merb" and second framework is going
      #      to be set to "rails".
      #
      #   2) All options and configurations are sent to the invoked class.
      #      So the invoked class is going to use the same shell instance, will
      #      have the same behavior (:invoke or :revoke) and so on.
      #
      # Invoking a Thor::Group happens in the same away as above:
      #
      #   class C < Thor::Group
      #     def one
      #     end
      #   end
      #
      # Is invoked as:
      #
      #   invoke "c"
      #
      # Or even as:
      #
      #   invoke C
      #
      def invoke(name, method_args=[], options={})
        instance, task = _setup_for_invoke(name, method_args, options)

        @invocations ||= Hash.new { |h,k| h[k] = [] }
        current = @invocations[instance.class]
        return if current.include?("all")

        if task
          task = self.class.all_tasks[task.to_s] || Task.dynamic(task) unless task.is_a?(Thor::Task)
          return if current.include?(task.name)

          current << task.name
          task.run(instance, method_args)
        else
          current << "all"
          instance.invoke_all
        end
      end

      protected

        # Common methods that are delegated to the shell.
        #
        SHELL_DELEGATED_METHODS.each do |method|
          module_eval <<-METHOD, __FILE__, __LINE__
            def #{method}(*args)
              shell.#{method}(*args)
            end
          METHOD
        end

        # This is the method responsable for retrieving and setting up an
        # instance to be used in invoke.
        #
        def _setup_for_invoke(name, method_args, options) #:nodoc:
          if name.is_a?(Thor::Task)
            # Do nothing, we already have what we want.
          elsif name.is_a?(Class)
            klass = name
          elsif self.class.all_tasks[name.to_s].nil?
            klass, task = Thor::Util.namespace_to_thor_class(name.to_s) rescue Thor::Error
          end

          case klass
            when Thor::Base
              size       = klass.arguments.size
              class_args = method_args.slice!(0, size)
              instance   = klass.new(class_args, self.options.merge(options), _dump_config)

              task ||= klass.default_task if klass.is_a?(Thor)
              instance.instance_variable_set("@invocations", @invocations)

              return instance, task
            when nil
              return self, name
            else
              raise ScriptError, "Expected Thor class, got #{klass}"
          end
        end

        # Dump the configuration values for this current class.
        #
        def _dump_config #:nodoc:
          { :shell => self.shell }
        end

    end
  end
end
