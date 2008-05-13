require "thor"
require "fileutils"

class Thor
  def self.package_task
    self.class_eval <<-RUBY, __FILE__, __LINE__ + 1
      desc "package", "package up the gem"
      def package
        FileUtils.mkdir_p(File.join(Dir.pwd, "pkg"))
        Gem::Builder.new(SPEC).build
        FileUtils.mv(SPEC.file_name, File.join(Dir.pwd, "pkg", SPEC.file_name))
      end    
    RUBY
  end
  
  def self.install_task
    package_task
    
    self.class_eval <<-RUBY, __FILE__, __LINE__ + 1
      desc "install", "install the gem"
      def install
        old_stderr, $stderr = $stderr.dup, File.open("/dev/null", "w")
        package
        $stderr = old_stderr
        system %{sudo gem install pkg/#{GEM}-#{GEM_VERSION} --no-rdoc --no-ri --no-update-sources}
      end
    RUBY
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
    
    self.class_eval <<-RUBY, __FILE__, __LINE__ + 1
      desc("#{name}", "spec task")
      def #{name}
        cmd = "ruby "
        if #{rcov.inspect}
          cmd << "-S rcov -o #{rcov_dir} #{rcov_opts.inspect[1...-1]} "
        end
        cmd << `which spec`.chomp
        cmd << " -- " if #{rcov.inspect}
        cmd << " "
        cmd << #{file_list.inspect}
        cmd << " "
        cmd << #{options.inspect}
        puts cmd if #{verbose.inspect}
        system(cmd)
      end
    RUBY
  end
  
  private
  def self.convert_task_options(opts)
    opts.map do |key, value|
      if value == true
        "--#{key}"
      elsif value.is_a?(Array)
        value.map {|v| "--#{key} #{v.inspect}"}.join(" ")
      else
        "--#{key} #{value.inspect}"
      end
    end.join(" ")    
  end  
end
