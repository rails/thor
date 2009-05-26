require 'thor'
require 'thor/tasks/runner'

class Thor::Runner < Thor

  # Override Thor#help so we can give info about not-yet-loaded tasks
  def help(task = nil)
    initialize_thorfiles(task) if task && task.include?(?:)
    super
  end

  def method_missing(meth, *args)
    meth = meth.to_s
    super(meth.to_sym, *args) unless meth.include?(?:)

    initialize_thorfiles(meth)
    klass, task = self.class.task_from_thor_class(meth)
    klass.invoke(task, ARGV[1..-1] || [])
  end

  def self.thor_root
    return File.join(ENV["HOME"], '.thor') if ENV["HOME"]

    if ENV["HOMEDRIVE"] && ENV["HOMEPATH"] then
      return File.join(ENV["HOMEDRIVE"], ENV["HOMEPATH"], '.thor')
    end
    
    return File.join(ENV["APPDATA"], '.thor') if ENV["APPDATA"]

    begin
      File.expand_path("~")
    rescue
      if File::ALT_SEPARATOR then
        "C:/"
      else
        "/"
      end
    end
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

  def self.task_from_thor_class(task)
    namespaces = task.split(":")
    klass = Thor::Util.constant_from_thor_path(namespaces[0...-1].join(":"))
    raise Error, "`#{klass}' is not a Thor class" unless klass <= Thor
    return klass, namespaces.last
  end

  def self.globs_for(path)
    ["#{path}/Thorfile", "#{path}/*.thor", "#{path}/tasks/*.thor", "#{path}/lib/tasks/*.thor"]
  end

  private

  def thor_root
    self.class.thor_root
  end

  def thor_root_glob
    self.class.thor_root_glob
  end

  def initialize_thorfiles(relevant_to = nil)
    thorfiles(relevant_to).each do |f|
      load_thorfile(f) unless Thor.subclass_files.keys.include?(File.expand_path(f))
    end
  end
  
  def load_thorfile(path)
    txt = File.read(path)
    begin
      Thor::Tasks.class_eval(txt, path)
    rescue Object => e
      $stderr.puts "WARNING: unable to load thorfile #{path.inspect}: #{e.message}"
    end
  end
  
  # Finds Thorfiles by traversing from your current directory down to the root
  # directory of your system. If at any time we find a Thor file, we stop.
  #
  # ==== Example
  # If we start at /Users/wycats/dev/thor ...
  #
  # 1. /Users/wycats/dev/thor
  # 2. /Users/wycats/dev
  # 3. /Users/wycats <-- we find a Thorfile here, so we stop
  #
  # Suppose we start at c:\Documents and Settings\james\dev\thor ...
  #
  # 1. c:\Documents and Settings\james\dev\thor
  # 2. c:\Documents and Settings\james\dev
  # 3. c:\Documents and Settings\james
  # 4. c:\Documents and Settings
  # 5. c:\ <-- no Thorfiles found!
  def thorfiles(relevant_to=nil)
    thorfiles = []

    # This may seem a little odd at first. Suppose you're working on a Rails 
    # project and you traverse into the "app" directory. Because of the below 
    # you can execute "thor -T" and see any tasks you might have in the root 
    # directory of your Rails project.
    Pathname.pwd.ascend do |path|
      thorfiles = Thor::Runner.globs_for(path).map { |g| Dir[g] }.flatten
      break unless thorfiles.empty?
    end

    # We want to load system-wide Thorfiles first so the local Thorfiles will 
    # override them.
    files  = (relevant_to ? thorfiles_relevant_to(relevant_to) : thor_root_glob)
    files += thorfiles - ["#{thor_root}/thor.yml"]
     
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
