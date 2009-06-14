require 'fileutils'

Dir[File.join(File.dirname(__FILE__), "actions", "*.rb")].each do |action|
  require action
end

class Thor
  module Actions
    attr_accessor :behavior

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

    # Sets the root for this thor class. Relatives path are added to the
    # directory where the script was invoked and expanded.
    #
    def root=(root)
      @root_stack ||= []
      @root_stack[0] = File.expand_path(root || '')
    end

    # Returns the root for this thor class (also aliased as destination root).
    #
    def root
      @root_stack.last
    end
    alias :destination_root :root

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
    def inside(dir='', log_status=true, &block)
      @root_stack.push File.expand_path(dir, root)

      say_status_if_log :inside, root, log_status

      FileUtils.mkdir_p(root) unless File.exist?(root)
      FileUtils.cd(root) { block.arity == 1 ? yield(root) : yield }

      @root_stack.pop
    end

    # Goes to the root and execute the given block.
    #
    def in_root
      inside(@root_stack.first, false) { yield }
    end

    # Executes a command.
    #
    # ==== Parameters
    # command<String>:: the command to be executed.
    # log_status<Boolean>:: if false, does not log the status. True by default.
    #                       If a symbol is given, uses it as the output color.
    #
    # ==== Example
    #
    #   inside('vendor') do
    #     run('ln -s ~/edge rails')
    #   end
    #
    def run(command, log_status=true)
      say_status_if_log :run, "#{command} from #{Dir.pwd}", log_status
      `#{command}` unless options[:pretend]
    end

    # Executes a ruby script (taking into account WIN32 platform quirks).
    #
    # ==== Parameters
    # command<String>:: the command to be executed.
    # log_status<Boolean>:: if false, does not log the status. True by default.
    #                       If a symbol is given, uses it as the output color.
    #
    def run_ruby_script(command, log_status=true)
      run("ruby #{command}", log_status)
    end

    # Run a command in git.
    #
    # ==== Parameters
    # command<String>:: the command to be executed.
    # log_status<Boolean>:: if false, does not log the status. True by default.
    #                       If a symbol is given, uses it as the output color.
    #
    # ==== Examples
    #
    #   git :init
    #   git :add => "this.file that.rb"
    #   git :add => "onefile.rb", :rm => "badfile.cxx"
    #
    def git(command, log_status=true)
      in_root do
        if command.is_a?(Symbol)
          run "git #{command}", log_status
        else
          command.each do |command, options|
            run "git #{command} #{options}", log_status
          end
        end
      end
    end

    # Run a thor command. A hash of options can be given and it's converted to 
    # switches.
    #
    # ==== Parameters
    # task<String>:: the task to be invoked
    # args<Array>:: arguments to the task
    # options<Hash>:: a hash with options used on invocation
    # log_status<Boolean>:: if false, does not log the status. True by default.
    #                       If a symbol is given, uses it as the output color.
    #
    # ==== Examples
    #
    #   thor :install, "http://gist.github.com/103208"
    #   #=> thor install http://gist.github.com/103208
    #
    #   thor :list, :all => true, :substring => 'rails'
    #   #=> thor list --all --substring=rails
    #
    def thor(task, *args)
      log_status = [true, false].include?(args.last) ? args.pop : true
      options = args.last.is_a?(Hash) ? args.pop : {}

      in_root do
        args.unshift "thor #{task}"
        args.push Thor::Options.to_switches(options)
        run args.join(' ').strip, log_status
      end
    end

    protected

      def say_status_if_log(status, message, log_status)
        color = log_status.is_a?(Symbol) ? log_status : :green
        shell.say_status status, message, color if log_status
      end

  end
end
