$:.unshift File.expand_path(File.dirname(__FILE__))
require "getopt"

class Thor
  def self.inherited(klass)
    subclass_files[File.expand_path(caller[0].split(":")[0])] << klass
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
    @descriptions ||= []
    @usages ||= []
    @opts ||= []

    @descriptions.delete(@descriptions.assoc(meth))
    @descriptions << [meth, @desc]

    @usages.delete(@usages.assoc(meth))
    @usages << [meth, @usage]
    
    @opts.delete(@opts.assoc(meth))    
    @opts << [meth, @method_options] if @method_options

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

  def self.help_list
    return nil unless @usages
    @help_list ||= begin
      max_usage = @usages.max {|x,y| x.last.to_s.size <=> y.last.to_s.size}.last.size
      max_opts  = @opts.empty? ? 0 : format_opts(@opts.max {|x,y| x.last.to_s.size <=> y.last.to_s.size}.last).size 
      max_desc  = @descriptions.max {|x,y| x.last.to_s.size <=> y.last.to_s.size}.last.size
      Struct.new(:klass, :usages, :opts, :descriptions, :max).new(
        self, @usages, @opts, @descriptions, Struct.new(:usage, :opt, :desc).new(max_usage, max_opts, max_desc)
      )
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
    
    if @opts.assoc(meth)
      opts = @opts.assoc(meth).last.map {|opt, val| [opt, val == true ? Getopt::BOOLEAN : Getopt.const_get(val)].flatten}
      options = Getopt::Long.getopts(*opts)
      params << options
    end
    
    ARGV.replace args
    
    new(meth, params).instance_variable_get("@results")
  end

  def init(op, params)
    begin
      op ||= "help"
      @results = send(op.to_sym, *params) if public_methods.include?(op) || !methods.include?(op)
    rescue ArgumentError
      puts "`#{op}' was called incorrectly. Call as `#{usage(op)}'"
    end
  end
  
  def initialize(op, params)
    init(op, params)
  end
  
  def usage(meth)
    list = self.class.help_list
    list.usages.assoc(meth)[1] + (list.opts.assoc(meth) ? " " + self.class.format_opts(list.opts.assoc(meth)[1]) : "")
  end
  
  map "--help" => :help
  
  desc "help", "show this screen"
  def help
    list = self.class.help_list
    puts "Options"
    puts "-------"
    list.usages.each do |meth, use|
      format = "%-" + (list.max.usage + list.max.opt + 4).to_s + "s"
      print format % ("#{usage(meth)}")
      puts  list.descriptions.assoc(meth)[1]
    end
  end
  
end