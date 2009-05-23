$:.unshift File.expand_path(File.dirname(__FILE__))
require "thor/options"
require "thor/util"
require "thor/task"
require "thor/task_hash"

class Thor
  attr_accessor :options

  # Sets the default task when thor is executed without an explicit task to be called.
  #
  # ==== Parameters
  # meth<Symbol>:: name of the defaut task
  #
  def self.default_task(meth=nil)
    unless meth.nil?
      @default_task = (meth == :none) ? 'help' : meth.to_s
    end
    @default_task ||= (self == Thor ? 'help' : superclass.default_task)
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
  # Hash[String|Array => Symbol]:: Maps the string or the string in the array to the given task.
  #
  def self.map(map)
    @map ||= superclass.instance_variable_get("@map") || {}

    map.each do |key, value|
      if key.respond_to?(:each)
        key.each {|subkey| @map[subkey] = value}
      else
        @map[key] = value
      end
    end
  end

  # Defines the usage and the description of the next task.
  #
  # ==== Parameters
  # usage<String>
  # description<String>
  #
  def self.desc(usage, description)
    @usage, @desc = usage, description
  end

  # Defines the group. This is used when thor list is invoked so you can specify
  # that only tasks from a pre-defined group will be shown. Defaults to standard.
  #
  # ==== Parameters
  # name<String|Symbol>
  #
  def self.group(name)
    @group_name = name.to_s
  end
  
  # Returns the group name.
  #
  # ==== Returns
  # String
  #
  def self.group_name
    @group_name || 'standard'
  end
  
  # Declares the options for the next task to be declaread.
  #
  # ==== Parameters
  # Hash[Symbol => Symbol]:: The hash key is the name of the option and the value
  # is the type of the option. Can be :optional, :required, :boolean or :numeric.
  #
  def self.method_options(opts)
    @method_options = (@method_options || {}).merge(opts)
  end

  # Returns the files where the subclasses are maintained.
  #
  # ==== Returns
  # Hash[path<String> => Class]
  #
  def self.subclass_files
    @subclass_files ||= Hash.new {|h,k| h[k] = []}
  end

  # Returns the subclasses. Subclasses are dynamically added to the array when
  # a class inherits from the Thor class.
  #
  # ==== Returns
  # Array[Class]
  #
  def self.subclasses
    @subclasses ||= []
  end

  # Returns the tasks for this Thor class in an ordered hash.
  #
  # ==== Returns
  # TaskHash:: An ordered hash with this class tasks.
  #
  def self.tasks
    @tasks ||= TaskHash.new(self)
  end

  # Returns the options for this Thor class. Those option are declared by calling
  # method_options before calling initialize.
  #
  # ==== Returns
  # Hash[Symbol => Symbol]
  #
  def self.opts
    (@opts || {}).merge(self == Thor ? {} : superclass.opts)
  end

  def self.[](task)
    namespaces = task.split(":")
    klass = Thor::Util.constant_from_thor_path(namespaces[0...-1].join(":"))
    raise Error, "`#{klass}' is not a Thor class" unless klass <= Thor
    klass.tasks[namespaces.last]
  end

  def self.maxima
    @maxima ||= begin
      max_usage = tasks.map {|_, t| t.usage}.max {|x,y| x.to_s.size <=> y.to_s.size}.size
      max_desc  = tasks.map {|_, t| t.description}.max {|x,y| x.to_s.size <=> y.to_s.size}.size
      max_opts  = tasks.map {|_, t| t.opts ? t.opts.formatted_usage : ""}.max {|x,y| x.to_s.size <=> y.to_s.size}.size
      Struct.new(:description, :usage, :opt).new(max_desc, max_usage, max_opts)
    end
  end
  
  def self.start(args = ARGV)
    
    options = Thor::Options.new(self.opts)
    opts = options.parse(args, false)
    args = options.trailing_non_opts

    meth = args.first
    meth = @map[meth].to_s if @map && @map[meth]
    meth ||= default_task
    meth = meth.to_s.gsub('-','_') # treat foo-bar > foo_bar
    
    tasks[meth].parse new(opts, *args), args[1..-1]
  rescue Thor::Error => e
    $stderr.puts e.message
  end
  
  # Invokes a specific task.  You can use this method instead of start() 
  # to run a thor task if you know the specific task you want to invoke.
  def self.invoke(task_name=nil, args = ARGV)
    args = args.dup
    args.unshift(task_name || default_task)
    start(args)
  end

  # Main entry point method that should actually invoke the method.  You
  # can override this to provide some class-wide processing.  The default
  # implementation simply invokes the named method
  def invoke(meth, *args)
    self.send(meth, *args)
  end
  
  class << self
    protected
    def inherited(klass)
      register_klass_file klass
    end

    def method_added(meth)
      meth = meth.to_s
      
      if meth == "initialize"
        @opts = @method_options
        @method_options = nil
        return
      end

      return if !public_instance_methods.include?(meth) || !@usage
      register_klass_file self

      tasks[meth] = Task.new(meth, @desc, @usage, @method_options)

      @usage, @desc, @method_options = nil
    end

    def register_klass_file(klass, file = caller[1].match(/(.*):\d+/)[1])
      unless self == Thor
        superclass.register_klass_file(klass, file)
        return
      end

      file_subclasses = subclass_files[File.expand_path(file)]
      file_subclasses << klass unless file_subclasses.include?(klass)
      subclasses << klass unless subclasses.include?(klass)
    end
  end

  def initialize(opts = {}, *args)
  end
  
  map ["-h", "-?", "--help", "-D"] => :help
  
  desc "help [TASK]", "describe available tasks or one specific task"
  def help(task = nil)
    if task
      if task.include? ?:
        task = self.class[task]
        namespace = true
      else
        task = self.class.tasks[task]
      end

      puts task.formatted_usage(namespace)
      puts task.description
    else
      puts "Options"
      puts "-------"
      self.class.tasks.each do |_, task|
        format = "%-" + (self.class.maxima.usage + self.class.maxima.opt + 4).to_s + "s"
        print format % ("#{task.formatted_usage}")      
        puts  task.description.split("\n").first
      end
    end
  end
  
end
