$:.unshift File.expand_path(File.dirname(__FILE__))
require "getopt"
require "thor/task"
require "thor/ordered_hash"

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

    @tasks ||= OrderedHash.new
    @tasks[meth] = Task.new(meth, self, @desc, @usage, @method_options)

    @usage, @desc, @method_options = nil
  end

  def self.map(map)
    @map ||= superclass.instance_variable_get("@map") || {}
    @map.merge! map
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
    (@tasks || OrderedHash.new) + (self == Thor ? OrderedHash.new : superclass.tasks)
  end

  def self.maxima
    @maxima ||= begin
      tasks = self.tasks
      max_usage = tasks.map {|_, t| t.usage}.max {|x,y| x.to_s.size <=> y.to_s.size}.size
      max_desc  = tasks.map {|_, t| t.description}.max {|x,y| x.to_s.size <=> y.to_s.size}.size
      opts      = tasks.map {|_, t| t.opts}.compact
      max_opts  = opts.empty? ? 0 : format_opts(opts.max {|x,y| x.to_s.size <=> y.to_s.size}).size 
      Struct.new(:description, :usage, :opt).new(max_desc, max_usage, max_opts)
    end
  end
  
  def self.format_opts(opts)
    return "" if !opts
    opts.map do |opt, val|
      if val == true || val == "BOOLEAN"
        "[#{opt}]"
      elsif val == "REQUIRED"
        opt + "=" + opt.gsub(/\-/, "").upcase
      elsif val == "OPTIONAL"
        "[" + opt + "=" + opt.gsub(/\-/, "").upcase + "]"
      end
    end.join(" ")
  end
  
  def self.start
    meth = ARGV.shift
    params = []
    while !ARGV.empty?
      break if ARGV.first =~ /^\-/
      params << ARGV.shift
    end
    if defined?(@map) && @map[meth]
      meth = @map[meth].to_s
    end
    
    args = ARGV.dup
    
    if tasks[meth] && tasks[meth].opts
      opts = tasks[meth].opts.map {|opt, val| [opt, val == true ? Getopt::BOOLEAN : Getopt.const_get(val)].flatten}
      options = Getopt::Long.getopts(*opts)
      params << options
    end
    
    ARGV.replace args
    
    new(meth, params).instance_variable_get("@results")
  end
  
  def initialize(op, params)
    begin
      op ||= "help"
      @results = send(op.to_sym, *params) if public_methods.include?(op) || !methods.include?(op)
    rescue ArgumentError
      puts "`#{op}' was called incorrectly. Call as `#{usage(op)}'"
    end
  end

  public :initialize
  
  def usage(meth)
    task = self.class.tasks[meth]
    task.usage + (task.opts ? " " + self.class.format_opts(task.opts) : "")
  end
  
  map "--help" => :help
  
  desc "help", "show this screen"
  def help
    puts "Options"
    puts "-------"
    self.class.tasks.each do |name, task|
      format = "%-" + (self.class.maxima.usage + self.class.maxima.opt + 4).to_s + "s"
      print format % ("#{usage(name)}")
      puts  task.description
    end
  end
  
end
