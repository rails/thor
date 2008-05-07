require "#{File.dirname(__FILE__)}/getopt"

class Thor
  def self.method_added(meth)
    return if !public_instance_methods.include?(meth.to_s) || !@usage
    @descriptions ||= []
    @usages ||= []
    @opts ||= []
    @descriptions << [meth.to_s, @desc]
    @usages << [meth.to_s, @usage]
    @opts << [meth.to_s, @method_options] if @method_options
    @usage, @desc, @method_options = nil
  end

  def self.map(map)
    @map = map
  end

  def self.desc(usage, description)
    @usage, @desc = usage, description
  end
  
  def self.method_options(opts)
    @method_options = opts.inject({}) do |accum, (k,v)|
      accum.merge("--" + k.to_s => v.to_s.upcase)
    end
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
    if @opts.assoc(meth)
      opts = @opts.assoc(meth).last.map {|opt, val| [opt, val == true ? Getopt::BOOLEAN : Getopt.const_get(val)].flatten}
      options = Getopt::Long.getopts(*opts)
      params << options
    end
    new(meth, params).instance_variable_get("@results")
  end
  
  def thor_usages
    self.class.instance_variable_get("@usages")
  end
  
  def thor_descriptions
    self.class.instance_variable_get("@descriptions")
  end

  def thor_opts
    self.class.instance_variable_get("@opts")
  end  
  

  def initialize(op, params)
    @results = send(op.to_sym, *params) if public_methods.include?(op)
  end
  
  private
  def format_opts(opts)
    return "" unless opts
    opts.map do |opt, val|
      if val == true || val == "BOOLEAN"
        opt
      elsif val == "REQUIRED"
        opt + "=" + opt.gsub(/\-/, "").upcase
      elsif val == "OPTIONAL"
        "[" + opt + "=" + opt.gsub(/\-/, "").upcase + "]"
      end
    end.join(" ")
  end
  
  public
  desc "help", "show this screen"
  def help
    puts "Options"
    puts "-------"
    max_usage = thor_usages.max {|x,y| x.last.to_s.size <=> y.last.to_s.size}.last.size
    max_opts  = thor_opts.empty? ? 0 : format_opts(thor_opts.max {|x,y| x.last.to_s.size <=> y.last.to_s.size}.last).size 
    max_desc  = thor_descriptions.max {|x,y| x.last.to_s.size <=> y.last.to_s.size}.last.size
    thor_usages.each do |meth, usage|
      format = "%-" + (max_usage + max_opts + 4).to_s + "s"
      print format % (thor_usages.assoc(meth)[1] + (thor_opts.assoc(meth) ? " " + format_opts(thor_opts.assoc(meth)[1]) : ""))
      puts  thor_descriptions.assoc(meth)[1]
    end
  end  
end