require 'thor/actions/empty_directory'

class Thor
  module Actions

    # Copies interactively the files from source directory to root directory.
    # Use it just to copy static files.
    #
    # ==== Parameters
    # source<String>:: the relative path to the source root
    # destination<String>:: the relative path to the destination root
    # log_status<Boolean>:: if false, does not log the status. True by default.
    #
    # ==== Examples
    #
    #   directory "doc"
    #
    def directory(source, destination=nil, log_status=true)
      action Directory.new(self, source, destination || source, log_status)
    end

    class Directory < EmptyDirectory #:nodoc:

      def invoke!
        files = Dir[File.join(source, '**', '*')].select{ |f| !File.directory?(f) }

        files.each do |file_source|
          file_destination = File.join(relative_destination, file_source.gsub(source, ''))
          file_source.gsub!(base.source_root, '.')
          base.copy_file(file_source, file_destination, @log_status)
        end
      end

    end
  end
end
