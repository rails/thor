class Thor::Wrapper < Thor
  
  private 

  # Returns the name of the parent (overridden or wrapped) command.
  def parent
    self.class.parent
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

    def handle_no_task_error(task) #:nodoc:
      forward(*ARGV)
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
      raise Thor::Error, "#{parent} is not installed" unless File.exists?(parent)
      raise Thor::Error, "#{parent} exists, but is not executable" unless File.executable?(parent)
    end

    def forward_command(*args) #:nodoc:
      "#{parent} #{args.join(' ')}"
    end

    # Returns tasks ready to be printed.
    def printable_tasks(all=true, subcommand=false)
      list = super
      Thor::Util.thor_classes_in(self).each do |klass|
        list += klass.printable_tasks(false)
      end
      list.sort!{ |a,b| a[0] <=> b[0] }
      list = list.map do |t|
        raise Thor::Error, "Unexpected help response from #{$0}: #{t[0].inspect} #{t.join(' ')}" unless t[0] =~ /^\s*([^\s]+)\s+(([^\s]+)(?:\s+(?:.+?))?)\s*$/
        ['child', $1, $3, $2, t[1]]
      end
      list += parent_tasks
      sorted_list = list.sort_by {|t| [t[1], t[2], t[0]]}
      task_definitions = sorted_list.inject({}) do |hsh, task|
        hsh[task[2]] = task unless hsh[task[2]]
        hsh
      end
      list = task_definitions.keys.sort.map {|task_name| task_definitions[task_name]}
      list.map {|t| t[3..-1]}
    end
    
    # Returns tasks of the parent command, ready to be printed.
    def parent_tasks
      (wrap('help').split("\n")[1..-1] || []).map do |t|
        raise Thor::Error, "Unexpected help response from #{parent}: #{t}" unless t =~ /^\s*([^\s]+)\s+(([^\s]+)(?:\s+(?:\S.*?))?)\s*(#.*?)\s*$/
        ['parent', $1, $3, $2, $4]
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
        forward("help", task_name)
      end
    end
  end
end
