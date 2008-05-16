$:.unshift File.expand_path(File.dirname(__FILE__))
require "getopt"
require "thor/task"
require "thor/task_hash"

class Thor
  def self.inherited(klass)
    register_klass_file klass
  end

  def self.register_klass_file(klass, file = caller[1].split(":")[0])
    unless self == Thor
      superclass.register_klass_file(klass, file)
      return
    end

    file_subclasses = subclass_files[File.expand_path(file)]
    file_subclasses << klass unless file_subclasses.include?(klass)
    subclasses << klass unless subclasses.include?(klass)
  end
  
  def self.subclass_files
    @subclass_files ||= Hash.new {|h,k| h[k] = []}
  end
  
  def self.subclasses
    @subclasses ||= []
  end
  
  def self.method_added(meth)
    meth = meth.to_s
    return if !public_instance_methods.include?(meth) || !@usage
    register_klass_file self

    @tasks ||= TaskHash.new(self)
    @tasks[meth] = Task.new(meth, @desc, @usage, @method_options)

    @usage, @desc, @method_options = nil
  end

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

  def self.desc(usage, description)
    @usage, @desc = usage, description
  end
  
  def self.method_options(opts)
    @method_options = opts.inject({}) do |accum, (k,v)|
      accum.merge("--" + k.to_s => v.to_s.upcase)
    end
  end

  def self.tasks
    @tasks || TaskHash.new(self)
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
      max_opts  = tasks.map {|_, t| t.formatted_opts}.max {|x,y| x.to_s.size <=> y.to_s.size}.size
      Struct.new(:description, :usage, :opt).new(max_desc, max_usage, max_opts)
    end
  end
  
  def self.start(args = ARGV)
    args = args.dup
    meth = args.shift
    params = []
    params << args.shift until args.empty? || args.first[0] == ?-
    meth = @map[meth].to_s if @map && @map[meth]
    meth ||= "help"
    task = tasks[meth]
    
    old_argv = ARGV.dup
    ARGV.replace args
    
    if task.opts
      opts = task.opts.map {|opt, val| [opt, val == true ? Getopt::BOOLEAN : Getopt.const_get(val)].flatten}
      options = Getopt::Long.getopts(*opts)
      params << options
    end
    
    ARGV.replace old_argv
    
    task.run(*params)
  rescue Thor::Error => e
    $stderr.puts e.message
  end
  
  map ["-h", "-?", "--help"] => :help
  
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
      return
    end

    puts "Options"
    puts "-------"
    self.class.tasks.each do |_, task|
      format = "%-" + (self.class.maxima.usage + self.class.maxima.opt + 4).to_s + "s"
      print format % ("#{task.formatted_usage}")      
      puts  task.description.split("\n").first
    end
  end
  
end
