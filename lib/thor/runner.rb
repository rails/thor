require 'thor/tasks/runner'

class Thor::Runner < Thor

  # Override Thor#help so it can give information about any class and any method.
  #
  def help(meth=nil)
    if meth && !self.respond_to?(meth)
      initialize_thorfiles(meth)
      klass, task = Thor::Util.namespace_to_thor_class(meth)
      klass.start(["-h", task].compact) # send mapping -h because it works with generators too
    else
      super
    end
  end

  # If a task is not found on Thor::Runner, method missing is invoked and
  # Thor::Runner is then responsable for finding the task in all classes.
  #
  def method_missing(meth, *args)
    meth = meth.to_s
    initialize_thorfiles(meth)
    klass, task = Thor::Util.namespace_to_thor_class(meth)
    args.unshift(task) if task
    klass.start(args)
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
      Thor::Util.load_thorfile(f) unless Thor::Base.subclass_files.keys.include?(File.expand_path(f))
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
    files += thorfiles
    files -= ["#{thor_root}/thor.yml"]

    files.map! do |file|
      File.directory?(file) ? File.join(file, "main.thor") : file
    end
  end

  def thorfiles_relevant_to(meth)
    thor_class      = Thor::Util.namespace_to_constant_name(meth.split(":")[0...-1].join(":"))
    generator_class = Thor::Util.namespace_to_constant_name(meth)
  
    thor_yaml.select do |k, v|
      v[:constants] && (v[:constants].include?(thor_class) || v[:constants].include?(generator_class))
    end.map { |k, v| File.join(thor_root, "#{v[:filename]}") }
  end
end
