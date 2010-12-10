class Thor::Wrapper < Thor
  
  private 
  
  def parent
    self.class.parent
  end
  
  def forward(*args)
    self.class.forward(*args)
  end
  
  def wrap(*args)
    self.class.wrap(*args)
  end

  class << self
        
    def wraps(s)
      @parent = s
    end

    def parent
      @parent
    end

    def handle_no_task_error(task) #:nodoc:
      forward(*ARGV)
    end
  
    def forward(*args)
      check_forward
      system forward_command(*args)
    end
    
    def wrap(*args)
      check_forward
      `#{forward_command(*args)}`
    end
    
    def check_forward
      raise Thor::Error, "#{parent} is not installed" unless File.exists?(parent)
      raise Thor::Error, "#{parent} exists, but is not executable" unless File.executable?(parent)
    end

    def forward_command(*args)
      "#{parent} #{args.join(' ')}"
    end

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
    
    def parent_tasks
      (wrap('help').split("\n")[1..-1] || []).map do |t|
        raise Thor::Error, "Unexpected help response from #{parent}: #{t}" unless t =~ /^\s*([^\s]+)\s+(([^\s]+)(?:\s+(?:\S.*?))?)\s*(#.*?)\s*$/
        ['parent', $1, $3, $2, $4]
      end
    end

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
