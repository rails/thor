require "thor/task"

class Thor::PackageTask < Thor::Task
  attr_accessor :spec
  attr_accessor :opts

  def initialize(gemspec, opts = {})
    super(:package, "build a gem package")
    @spec = gemspec
    @opts = {:dir => File.join(Dir.pwd, "pkg")}.merge(opts)
  end

  def run
    FileUtils.mkdir_p(@opts[:dir])
    Gem::Builder.new(spec).build
    FileUtils.mv(spec.file_name, File.join(@opts[:dir], spec.file_name))
  end
end
