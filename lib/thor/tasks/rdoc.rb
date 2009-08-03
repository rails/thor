require 'rdoc/rdoc'
require 'fileutils'

class Thor
  # Creates a rdoc task.
  #
  # ==== Parameters
  # path<String>:: Path to create rdoc from.
  #
  # ==== Options
  # :extra_rdoc_files - Extra rdoc files.
  # :destination - Where to create rdoc files (defaults to :rdoc).
  # :project - Project name (defaults to path :basename)
  # :readme - Main readme file
  #
  def self.rdoc_task(path, config={})
    tasks['rdoc'] = Thor::RdocTask.new(path, config)
  end

  class RdocTask < Task #:nodoc:
    attr_accessor :path, :config

    def initialize(path, config={})
      super(:rdoc, "Create rdoc documentation", "rdoc", {})
      @path   = File.expand_path(path)
      @config = {
        :destination => File.join(path, "rdoc"),
        :project => File.basename(path),
        :readme => File.basename(Dir.glob(File.join(path, "README*")).first || "README")
      }.merge(config)
    end

    def run(instance, args=[])
      FileUtils.rm_rf(@config[:destination])

      files = Dir.glob("#{path}/lib/**/*.rb")
      files += @config[:extra_rdoc_files] || []

      arguments = [
        "-t", @config[:project],
        "-m", @config[:readme],
        "--op", @config[:destination]
      ]

      puts "Rdoc for #{@config[:project]} (#{files.size} files) at #{@config[:destination]}"
      RDoc::RDoc.new.document(arguments + files)
    end
  end
end
