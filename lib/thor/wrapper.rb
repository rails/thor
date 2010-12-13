class Thor::Wrapper < Thor
  
  no_tasks do
    # Returns the name of the parent (overridden or wrapped) command.
    def parent
      self.class.parent
    end

    # Returns the path of the parent (overridden or wrapped) command.
    # Uses the current load_path to determine the path.
    def parent_path
      self.class.parent_path
    end
  
    # Forwards a command to the parent, using a system() call.
    # Output from the command is written to $stdout, etc. 
    # Returns the return code of the command.
    #
    # ==== Parameters
    # args<Array>:: Arguments for the parent command.
    def forward(*args)
      self.class.forward(*args)
    end
  
    # Forwards a command to the parent, using a backticks (``).
    # Returns the output (from $stdout) of the command.
    #
    # ==== Parameters
    # args<Array>:: Arguments for the parent command.
    def wrap(*args)
      self.class.wrap(*args)
    end
  end

  class << self
        
    # Define the command to be wrapped (the parent command).
    # For example:
    #
    #    class Foo < Thor::Wrapper
    #      wraps "/usr/bin/textmate"
    #      ...
    #    end
    #
    # ==== Parameters
    # args<Array>:: Arguments for the parent command.
    def wraps(s)
      @parent = s
    end

    # Returns the name of the parent (overridden or wrapped) command.
    def parent
      @parent
    end

    # Returns the path of the parent (overridden or wrapped) command.
    # Uses the current load_path to determine the path.
    def parent_path
      `which #{@parent.inspect}`.chomp
    end

    def handle_no_task_error(task) #:nodoc:
      forward(task, *original_arguments[1..-1])
    end
  
    # Forwards a command to the parent, using a system() call.
    # Output from the command is written to $stdout, etc. 
    # Returns the return code of the command.
    #
    # ==== Parameters
    # args<Array>:: Arguments for the parent command.
    def forward(*args)
      check_forward
      system forward_command(*args)
    end
    
    # Forwards a command to the parent, using a backticks (``).
    # Returns the output (from $stdout) of the command.
    #
    # ==== Parameters
    # args<Array>:: Arguments for the parent command.
    def wrap(*args)
      check_forward
      `#{forward_command(*args)}`
    end
    
    # Check that the parent command exists, and is executable.
    # Raises a Thor::Error if it isn't
    def check_forward
      raise Thor::Error, "Parent command has not been defined for #{self}. Use wraps method" unless @parent
      raise Thor::Error, "#{parent} is not installed" unless File.exists?(parent_path)
      raise Thor::Error, "#{parent} exists, but is not executable" unless File.executable?(parent_path)
      raise Thor::Error, "#{self} wraps itself: parent_path = #{parent_path}" if File.expand_path($0) == parent_path
    end

    def forward_command(*args) #:nodoc:
      "#{parent} #{args.map{|arg| arg.gsub(/ /,'\ ')}.join(' ')}"
    end

    # Returns tasks of the wrapper class (but not the parent)
    alias_method :child_printable_tasks, :printable_tasks
    
    # Returns all tasks of the wrapper class and its subclasses (but not the parent)
    # in printable form
    def child_and_subclass_tasks(all=true, subcommand=false)
      list = child_printable_tasks(all,subcommand)
      Thor::Util.thor_classes_in(self).each do |klass|
        list += klass.printable_tasks(false)
      end
      list.sort!{ |a,b| a[0] <=> b[0] }
    end
    
    # Returns all tasks of the wrapper class and its subclasses (but not the parent)
    # with each child task in the form [<taskname>, <taskusage>, <description>]
    def child_and_subclass_task_specs(all=true, subcommand=false)
      child_and_subclass_tasks(all,subcommand).map do |t|
        raise Thor::Error, "Unexpected help response from #{$0}: #{t[0].inspect} #{t.join(' ')}" unless t[0] =~ /^\s*([^\s]+)\s+(([^\s]+)(?:\s+(?:.+?))?)\s*$/
        [$1, $3, $2, t[1]]
      end
    end
    
    # Returns tasks ready to be printed.
    def printable_tasks(all=true, subcommand=false)
      list = child_and_subclass_task_specs(all, subcommand).map{|t| t.unshift('child')}
      list += parent_task_specs.map{|t| t[1..-1].unshift(basename).unshift('parent')}
      sorted_list = list.sort_by {|t| [t[1], t[2], t[0]]} # Note that child tasks come before parent tasks
      # Override parent task definitions with child task definitions
      task_definitions = sorted_list.inject({}) do |hsh, task|
        hsh[task[2]] = task unless hsh[task[2]]
        hsh
      end
      # Reconvert to list in the usual [<task_usage>, <description>] format, sorted by task name
      task_definitions.keys.sort.map {|task_name| t = task_definitions[task_name]; ["#{basename} #{t[3]}", t[4]]}
    end
    
    # Returns tasks of the parent command. Each task should be formatted in the form
    # [<parent>, <taskname>, <taskusage>, <description>]
    # This version is designed to work where the parent command is a Thor command
    # If you want to wrap a non-Thor command, you should override this method to parse its help syntax
    def parent_task_specs
      (wrap('help').split("\n")[1..-1] || []).map do |t|
        raise Thor::Error, "Unexpected help response from #{parent}: #{t}" unless t =~ /^\s*([^\s]+)\s+(([^\s]+)(?:\s+(?:\S.*?))?)\s*(#.*?)\s*$/
        [$1, $3, $2, $4]
      end
    end

    # Prints help information for the given task.
    #
    # ==== Parameters
    # shell<Thor::Shell>
    # task_name<String>
    #
    def task_help(shell, task_name)
      meth = normalize_task_name(task_name)
      if all_tasks[meth]
        super
      else
        shell.say wrap("help", task_name).gsub(parent,basename)
      end
    end
  end
end
