require 'fileutils'

Dir[File.join(File.dirname(__FILE__), "actions", "*.rb")].each do |action|
  require action
end

class Thor
  module Actions
    attr_accessor :behavior

    # On inclusion, add some options to base.
    #
    def self.included(base) #:nodoc:
      return unless base.respond_to?(:class_option)

      base.class_option :pretend, :type => :boolean, :aliases => "-p",
                                  :desc => "Run but do not make any changes"

      base.class_option :force, :type => :boolean, :aliases => "-f",
                                :desc => "Overwrite files that already exist"

      base.class_option :skip, :type => :boolean, :aliases => "-s",
                               :desc => "Skip files that already exist"

      base.class_option :quiet, :type => :boolean, :aliases => "-q",
                                :desc => "Supress status output"

      # TODO Add git support
      base.class_option :git, :type => :boolean, :aliases => "-g",
                              :desc => "Modify files with git (note: git must be on the path)"

      # TODO Add chmod support
      base.class_option :chmod, :type => :string, :aliases => "-c",
                                :desc => "Set the mode of added/copied files"
    end

    # Extends initializer to add more configuration options.
    #
    # ==== Configuration
    # behavior<Symbol>:: The actions default behavior. Can be :invoke or :revoke.
    #                    It also accepts :force, :skip and :pretend to set the behavior
    #                    and the respective option.
    #
    # root<String>:: The root directory needed for some actions. It's also known
    #                as destination root.
    #
    # in_root<Boolean>:: When true, creates the root directory if it does not exist
    #                    and move to it. False by default.
    #
    def initialize(args=[], options={}, config={})
      self.behavior = case config[:behavior]
        when :force
          options.merge!(:force => true, 'force' => true)
          :invoke
        when :skip
          options.merge!(:skip => true, 'skip' => true)
          :invoke
        when :pretend
          options.merge!(:pretend => true, 'pretend' => true)
          :invoke
        when :revoke
          :revoke
        else
          :invoke
      end

      self.root = config[:root]
      if config[:in_root]
        FileUtils.mkdir_p(root) unless File.exist?(root)
        FileUtils.cd(root)
      end

      super
    end

    # Wraps an action object and call it accordingly to the thor class behavior.
    #
    def action(instance)
      if behavior == :revoke
        instance.revoke!
      else
        instance.invoke!
      end
    end

    # Returns the root for this thor class (also aliased as destination root).
    #
    def root
      @root_stack.last
    end
    alias :destination_root :root

    # Sets the root for this thor class. Relatives path are added to the
    # directory where the script was invoked and expanded.
    #
    def root=(root)
      @root_stack ||= []
      @root_stack[0] = File.expand_path(root || '')
    end

    # Returns the given path relative to the absolute root (ie, root where
    # the script started).
    #
    def relative_to_absolute_root(path, remove_dot=true)
      path = path.gsub(@root_stack[0], '.')
      remove_dot ? path[2..-1] : path
    end

    # Get the source root in the class. Raises an error if a source root is
    # not specified in the thor class.
    #
    def source_root
      self.class.source_root
    rescue NoMethodError => e
      raise NoMethodError, "You have to specify the class method source_root in your thor class."
    end

    # Do something in the root or on a provided subfolder. If a relative path
    # is given it's referenced from the current root. The full path is yielded
    # to the block you provide. The path is set back to the previous path when
    # the method exits.
    #
    # ==== Parameters
    # dir<String>:: the directory to move to.
    # log_status<Boolean>:: if false, does not log the status. True by default.
    #                       If a symbol is given, uses it as the output color.
    #
    def inside(dir='', &block)
      @root_stack.push File.expand_path(dir, root)
      FileUtils.mkdir_p(root) unless File.exist?(root)
      FileUtils.cd(root) { block.arity == 1 ? yield(root) : yield }
      @root_stack.pop
    end

    # Goes to the root and execute the given block.
    #
    def in_root
      inside(@root_stack.first) { yield }
    end

    protected

      def say_status_if_log(status, message, log_status)
        color = log_status.is_a?(Symbol) ? log_status : :green
        shell.say_status status, message, color if log_status
      end

  end
end
