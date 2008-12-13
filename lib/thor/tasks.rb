require "thor"
require "fileutils"

class Thor
  def self.package_task(spec)
    desc "package", "package up the gem"
    define_method :package do
      FileUtils.mkdir_p(File.join(Dir.pwd, "pkg"))
      Gem::Builder.new(spec).build
      FileUtils.mv(spec.file_name, File.join(Dir.pwd, "pkg", spec.file_name))
    end
  end
  
  def self.install_task(spec)
    package_task spec

    null, sudo, gem = RUBY_PLATFORM =~ /w(in)?32$/ ? ['NUL', '', 'gem.bat'] :
                                                     ['/dev/null', 'sudo', 'gem']
    
    desc "install", "install the gem"
    define_method :install do
      old_stderr, $stderr = $stderr.dup, File.open(null, "w")
      package
      $stderr = old_stderr
      system %{#{sudo} #{Gem.ruby} -S #{gem} install pkg/#{spec.name}-#{spec.version} --no-rdoc --no-ri --no-update-sources}
    end
  end
  
  def self.spec_task(file_list, opts = {})
    name = opts.delete(:name) || "spec"
    rcov_dir = opts.delete(:rcov_dir) || "coverage"
    file_list = file_list.map {|f| %["#{f}"]}.join(" ")
    verbose = opts.delete(:verbose)
    opts = {:format => "specdoc", :color => true}.merge(opts)
    
    rcov_opts = convert_task_options(opts.delete(:rcov) || {})
    rcov = !rcov_opts.empty?
    options = convert_task_options(opts)
    
    if rcov
      FileUtils.rm_rf(File.join(Dir.pwd, rcov_dir))
    end
    
    desc(name, "spec task")
    define_method(name) do
      cmd = "ruby "
      if rcov
        cmd << "-S rcov -o #{rcov_dir} #{rcov_opts} "
      end
      cmd << `which spec`.chomp
      cmd << " -- " if rcov
      cmd << " "
      cmd << file_list
      cmd << " "
      cmd << options
      puts cmd if verbose
      system(cmd)
      exit($?.exitstatus)
    end
  end
  
  private
  def self.convert_task_options(opts)
    opts.map do |key, value|
      case value
      when true
        "--#{key}"
      when Array
        value.map {|v| "--#{key} #{v.inspect}"}.join(" ")
      when nil, false
        ""
      else
        "--#{key} #{value.inspect}"
      end
    end.join(" ")    
  end  
end
