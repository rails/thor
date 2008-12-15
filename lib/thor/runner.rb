require 'thor'
require "thor/util"
require "open-uri"
require "fileutils"
require "yaml"
require "digest/md5"
require "readline"

class Thor::Runner < Thor
  
  def self.globs_for(path)
    ["#{path}/Thorfile", "#{path}/*.thor", "#{path}/tasks/*.thor", "#{path}/lib/tasks/*.thor"]
  end

  map "-T" => :list, "-i" => :install, "-u" => :update
  
  desc "install NAME", "install a Thor file into your system tasks, optionally named for future updates"
  method_options :as => :optional, :relative => :boolean
  def install(name)
    initialize_thorfiles

    base = name
    package = :file

    begin
      if File.directory?(File.expand_path(name))
        base, package = File.join(name, "main.thor"), :directory
        contents = open(base).read
      else
        contents = open(name).read
      end
    rescue OpenURI::HTTPError
      raise Error, "Error opening URI `#{name}'"
    rescue Errno::ENOENT
      raise Error, "Error opening file `#{name}'"
    end
    
    is_uri = File.exist?(name) ? false : true
    
    puts "Your Thorfile contains: "
    puts contents
    print "Do you wish to continue [y/N]? "
    response = Readline.readline
    
    return false unless response =~ /^\s*y/i
    
    constants = Thor::Util.constants_in_contents(contents, base)
    
    as = options["as"] || begin
      first_line = contents.split("\n")[0]
      (match = first_line.match(/\s*#\s*module:\s*([^\n]*)/)) ? match[1].strip : nil
    end
        
    if !as
      print "Please specify a name for #{name} in the system repository [#{name}]: "
      as = Readline.readline
      as = name if as.empty?
    end
    
    FileUtils.mkdir_p thor_root
    
    yaml_file = File.join(thor_root, "thor.yml")
    FileUtils.touch(yaml_file)
    yaml = thor_yaml
    
    location = (options[:relative] || is_uri) ? name : File.expand_path(name)
    yaml[as] = {:filename => Digest::MD5.hexdigest(name + as), :location => location, :constants => constants}
    
    save_yaml(yaml)
    
    puts "Storing thor file in your system repository"
    
    destination = File.join(thor_root, yaml[as][:filename])
    
    if package == :file
      File.open(destination, "w") {|f| f.puts contents }
    else
      FileUtils.cp_r(name, destination)
    end
    
    yaml[as][:filename] # Indicate sucess
  end
  
  desc "uninstall NAME", "uninstall a named Thor module"
  def uninstall(name)
    yaml = thor_yaml
    raise Error, "Can't find module `#{name}'" unless yaml[name]
    
    puts "Uninstalling #{name}."
    
    file = File.join(thor_root, "#{yaml[name][:filename]}")
    FileUtils.rm_rf(file)
    yaml.delete(name)
    save_yaml(yaml)
    
    puts "Done."
  end
  
  desc "update NAME", "update a Thor file from its original location"
  def update(name)
    yaml = thor_yaml
    raise Error, "Can't find module `#{name}'" if !yaml[name] || !yaml[name][:location]

    puts "Updating `#{name}' from #{yaml[name][:location]}"
    old_filename = yaml[name][:filename]
    self.options = self.options.merge("as" => name)
    filename = install(yaml[name][:location])
    unless filename == old_filename
      File.delete(File.join(thor_root, old_filename))
    end
  end
  
  desc "installed", "list the installed Thor modules and tasks (--internal means list the built-in tasks as well)"
  method_options :internal => :boolean
  def installed
    thor_root_glob.each do |f|
      next if f =~ /thor\.yml$/
      load_thorfile f unless Thor.subclass_files.keys.include?(File.expand_path(f))
    end

    klasses = Thor.subclasses
    klasses -= [Thor, Thor::Runner] unless options['internal']
    display_klasses(true, klasses)
  end
  
  desc "list [SEARCH]", "list the available thor tasks (--substring means SEARCH can be anywhere in the module)"
  method_options :substring => :boolean,
                 :group => :optional,
                 :all => :boolean
  def list(search = "")
    initialize_thorfiles
    search = ".*#{search}" if options["substring"]
    search = /^#{search}.*/i
    group  = options[:group] || 'standard'

    classes = Thor.subclasses.select do |k|
      (options[:all] || k.group_name == group) && 
      Thor::Util.constant_to_thor_path(k.name) =~ search
    end
    display_klasses(false, classes)
  end

  # Override Thor#help so we can give info about not-yet-loaded tasks
  def help(task = nil)
    initialize_thorfiles(task) if task && task.include?(?:)
    super
  end
    
  def method_missing(meth, *args)
    meth = meth.to_s
    super(meth.to_sym, *args) unless meth.include? ?:

    initialize_thorfiles(meth)
    task = Thor[meth]
    task.parse task.klass.new, ARGV[1..-1]
  end

  def self.thor_root
    File.join(ENV["HOME"] || ENV["APPDATA"], ".thor")
  end

  def self.thor_root_glob
    # On Windows thor_root will be something like this:
    #
    #   C:\Documents and Settings\james\.thor
    #
    # If we don't #gsub the \ character, Dir.glob will fail.
    files = Dir["#{thor_root.gsub(/\\/, '/')}/*"]
    files.map! do |file|
      File.directory?(file) ? File.join(file, "main.thor") : file
    end
  end
  
  private
  def thor_root
    self.class.thor_root
  end

  def thor_root_glob
    self.class.thor_root_glob
  end
  
  def thor_yaml
    yaml_file = File.join(thor_root, "thor.yml")
    yaml = YAML.load_file(yaml_file) if File.exists?(yaml_file)
    yaml || {}
  end
  
  def save_yaml(yaml)
    yaml_file = File.join(thor_root, "thor.yml")
    File.open(yaml_file, "w") {|f| f.puts yaml.to_yaml }
  end
  
  def display_klasses(with_modules = false, klasses = Thor.subclasses)
    klasses -= [Thor, Thor::Runner] unless with_modules
    raise Error, "No Thor tasks available" if klasses.empty?
    
    if with_modules && !(yaml = thor_yaml).empty?
      max_name = yaml.max {|(xk,xv),(yk,yv)| xk.to_s.size <=> yk.to_s.size }.first.size
      modules_label = "Modules"
      namespaces_label = "Namespaces"
      column_width = [max_name + 4, modules_label.size + 1].max
      
      print "%-#{column_width}s" % modules_label
      puts namespaces_label
      print "%-#{column_width}s" % ("-" * modules_label.size)
      puts "-" * namespaces_label.size
      
      yaml.each do |name, info|
        print "%-#{column_width}s" % name
        puts info[:constants].map {|c| Thor::Util.constant_to_thor_path(c)}.join(", ")
      end
    
      puts
    end
    
    # Calculate the largest base class name
    max_base = klasses.max do |x,y| 
      Thor::Util.constant_to_thor_path(x.name).size <=> Thor::Util.constant_to_thor_path(y.name).size
    end.name.size
    
    # Calculate the size of the largest option description
    max_left_item = klasses.max do |x,y| 
      (x.maxima.usage + x.maxima.opt).to_i <=> (y.maxima.usage + y.maxima.opt).to_i
    end
    
    max_left = max_left_item.maxima.usage + max_left_item.maxima.opt
    
    unless klasses.empty?
      puts # add some spacing
      klasses.each { |k| display_tasks(k, max_base, max_left); }
    else
      puts "\033[1;34mNo Thor tasks available\033[0m"
    end
  end  
  
  def display_tasks(klass, max_base, max_left)
    if klass.tasks.values.length > 1
      
      base = Thor::Util.constant_to_thor_path(klass.name)
      
      if base.to_a.empty?
        base = 'default' 
        puts "\033[1;35m#{base}\033[0m"
      else
        puts "\033[1;34m#{base}\033[0m"
      end
      puts "-" * base.length
      
      klass.tasks.each true do |name, task|
        format_string = "%-#{max_left + max_base + 5}s"
        print format_string % task.formatted_usage(true)
        puts task.description
      end
      
      unless klass.opts.empty?
        puts "\nglobal options: #{Options.new(klass.opts)}"
      end
      
      puts # add some spacing
    end
  end

  def initialize_thorfiles(relevant_to = nil)
    thorfiles(relevant_to).each {|f| load_thorfile f unless Thor.subclass_files.keys.include?(File.expand_path(f))}
  end
  
  def load_thorfile(path)
    txt = File.read(path)
    begin
      Thor::Tasks.class_eval txt, path
    rescue Object => e
      $stderr.puts "WARNING: unable to load thorfile #{path.inspect}: #{e.message}"
    end
  end
  
  def thorfiles(relevant_to = nil)
    path = Dir.pwd
    thorfiles = []
    
    # Look for Thorfile or *.thor in the current directory or a parent directory, until the root
    while thorfiles.empty?
      thorfiles = Thor::Runner.globs_for(path).map {|g| Dir[g]}.flatten
      path = File.dirname(path)
      break if path == "/"
    end

    # We want to load system-wide Thorfiles first
    # so the local Thorfiles will override them.
    files = (relevant_to ? thorfiles_relevant_to(relevant_to) :
     thor_root_glob) + thorfiles - ["#{thor_root}/thor.yml"]
     
    files.map! do |file|
      File.directory?(file) ? File.join(file, "main.thor") : file
    end
  end

  def thorfiles_relevant_to(meth)
    klass_str = Thor::Util.to_constant(meth.split(":")[0...-1].join(":"))
    thor_yaml.select do |k, v|
      v[:constants] && v[:constants].include?(klass_str)
    end.map { |k, v| File.join(thor_root, "#{v[:filename]}") }
  end

end
