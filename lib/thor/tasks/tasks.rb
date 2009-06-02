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

    null, sudo, gem = RUBY_PLATFORM =~ /mswin|mingw/ ? ['NUL', '', 'gem.bat'] :
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

    rcov_opts = Thor::Options.to_switches(opts.delete(:rcov) || {})
    rcov = !rcov_opts.empty?
    options = Thor::Options.to_switches(opts)

    if rcov
      FileUtils.rm_rf(File.join(Dir.pwd, rcov_dir))
    end
    
    desc(name, "spec task")
    define_method(name) do
      require 'rbconfig'
      cmd = RbConfig::CONFIG['ruby_install_name'] << " "
      if rcov
        cmd << "-S #{where('rcov')} -o #{rcov_dir} #{rcov_opts} "
      end
      cmd << where('spec')
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

    def where(file)
      ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
        file_with_path = File.join(path, file)
        next unless File.exist?(file_with_path) && File.executable?(file_with_path)
        return File.expand_path(file_with_path)
      end
    end
end
