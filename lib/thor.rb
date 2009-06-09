$:.unshift File.expand_path(File.dirname(__FILE__))
require 'thor/base'
require 'thor/group'

class Thor

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
    # Hash[String|Array => Symbol]:: Maps the string or the strings in the array to the given task.
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

    # Declares the options for the next task to be declared.
    #
    # ==== Parameters
    # Hash[Symbol => Object]:: The hash key is the name of the option and the value
    # is the type of the option. Can be :optional, :required, :boolean or :numeric.
    #
    def method_options(options=nil)
      @method_options ||= Thor::CoreExt::OrderedHash.new
      build_options(options, @method_options) if options
      @method_options
    end

    # Adds an option to the set of class options. If :for is given as option,
    # it allows you to change the options from a previous defined task.
    #
    #   def previous_task
    #     # magic
    #   end
    #
    #   method_options :foo => :bar, :for => :previous_task
    #
    #   def next_task
    #     # magic
    #   end
    #
    # ==== Parameters
    # name<Symbol>:: The name of the argument.
    # options<Hash>:: The description, type, default value, aliases and if this option is required or not.
    #                 The type can be :string, :boolean, :numeric, :hash or :array. If none is given
    #                 a default type which accepts both (--name and --name=NAME) entries is assumed.
    #
    def method_option(name, options)
      scope = if options[:for]
        find_and_refresh_task(options[:for]).options
      else
        method_options
      end

      build_option(name, options, scope)
    end

    # Parse the options given and extract the task to be called from it. If no
    # method can be extracted from args the default task is invoked.
    #
    def start(args=ARGV)
      meth = normalize_task_name(args.shift)
      task = self[meth]
      instance, args = setup(args, task.options)
      task.run(instance, args)
    rescue Thor::Error, Thor::Options::Error => e
      $stderr.puts e.message
    end

    # Prints help information. If a task name is given, it shows information
    # only about the specific task.
    #
    # ==== Parameters
    # meth<String>:: An optional task name to print usage information about.
    #
    # ==== Options
    # namespace:: When true, shows the namespace in the output before the usage.
    # skip_inherited:: When true, does not show tasks from superclass.
    #
    def help(meth=nil, options={})
      meth, options = nil, meth if meth.is_a?(Hash)
      namespace = options[:namespace] ? self : nil

      if meth
        task = self.all_tasks[meth]
        raise Error, "task '#{meth}' could not be found in namespace '#{self.namespace}'" unless task

        puts "Usage:"
        puts "  #{task.formatted_usage(namespace)}"
        puts
        options_help
        puts task.description
      else
        if options[:short]
          list = self.tasks.map do |_, task|
            [ task.formatted_usage(namespace), task.short_description ]
          end

          Thor::Util.print_list(list, :skip_spacing => true)
        else
          options_help

          list = self.all_tasks.map do |_, task|
            [ task.formatted_usage(namespace), task.short_description ]
          end

          puts "Tasks:"
          Thor::Util.print_list(list)
        end
      end
    end

    protected

      def baseclass #:nodoc:
        Thor
      end

      def valid_task?(meth) #:nodoc:
        public_instance_methods.include?(meth) && @usage && @desc
      end

      def create_task(meth) #:nodoc:
        tasks[meth.to_s] = Thor::Task.new(meth, @desc, @usage, method_options)
        @usage, @desc, @method_options = nil
      end

      def initialize_added #:nodoc:
        class_options.merge!(method_options)
        @method_options = nil
      end

      # Receives a task name (can be nil), and try to get a map from it.
      # If a map can't be found use the sent name or the default task.
      #
      def normalize_task_name(meth) #:nodoc:
        mapping = map[meth.to_s]
        meth = mapping || meth || default_task
        meth.to_s.gsub('-','_') # treat foo-bar > foo_bar
      end

      def options_help #:nodoc:
        unless self.class_options.empty?
          list = self.class_options.map do |_, option|
            [ option.usage, option.description ]
          end

          puts "Global options:"
          Thor::Util.print_list(list)
          puts
        end
      end
  end

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

  include Thor::Base

  map HELP_MAPPINGS => :help

  desc "help [TASK]", "Describe available tasks or one specific task"
  def help(task=nil)
    self.class.help(task, :namespace => task && task.include?(?:))
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
