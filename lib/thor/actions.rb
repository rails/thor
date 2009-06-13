require 'fileutils'

Dir[File.join(File.dirname(__FILE__), "actions", "*.rb")].each do |action|
  require action
end

class Thor
  module Actions
    attr_accessor :behavior

    SHELL_DELEGATED_METHODS = [:ask, :yes?, :no?, :say, :print_list, :print_table]

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

    # Get the source root in the class. Raises an error if a source root is
    # not specified in the thor class.
    #
    def source_root
      self.class.source_root
    rescue NoMethodError => e
      raise NoMethodError, "You have to specify the class method source_root in your thor class."
    end

    # Common methods that are delegated to the shell.
    #
    SHELL_DELEGATED_METHODS.each do |method|
      module_eval <<-METHOD, __FILE__, __LINE__
        def #{method}(*args)
          shell.#{method}(*args)
        end
      METHOD
    end

    # Do something in the root or on a provided subfolder. The full path is
    # yielded to the block you provide. The path is set back to the previous
    # path when the method exits.
    #
    # ==== Parameters
    # dir<String>:: the directory to move to.
    # log_status<Boolean>:: if false, does not log the status. True by default.
    #                       If a symbol is given, uses it as the output color.
    #
    def inside(dir='', log_status=true, &block)
      folder = File.join(root, dir)

      color = log_status.is_a?(Symbol) ? log_status : :green
      shell.say_status :cd, folder, color if log_status

      FileUtils.mkdir_p(folder) unless File.exist?(folder)
      FileUtils.cd(folder) { block.arity == 1 ? yield(folder) : yield }
    end

    # Goes to the root and execute the given block.
    #
    def in_root
      FileUtils.cd(root) { yield }
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
    #     run('ln -s ~/edge rails)
    #   end
    #
    def run(command, log_status=true)
      color = log_status.is_a?(Symbol) ? log_status : :green
      shell.say_status :running, "#{command} from #{Dir.pwd}", color if log_status
      `#{command}`
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

    # Run a thor command. A hash of options options can be given and it's
    # converted to switches.
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
    #   thor :install, "http://gist.github.com/103208"  #=> thor install http://gist.github.com/103208
    #   thor :list, :all => true, :substring => 'rails' #=> thor list --all --substring=rails
    #
    def thor(task, *args)
      log_status = [true, false].include?(args.last) ? args.pop : true
      options = args.last.is_a?(Hash) ? args.pop : {}

      in_root do
        command = "thor #{task} #{args.join(' ')} #{Thor::Options.to_switches(options)}"
        run command.strip, log_status
      end
    end

  end
end
