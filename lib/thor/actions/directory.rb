require 'thor/actions/templater'

class Thor
  module Actions

    # Copies interactively the files from source directory to root directory.
    # If any of the files finishes with .tt, it's considered to be a template
    # and is placed in the destination without the extension .tt. If any
    # empty directory is found, it's copied and all .empty_directory files are
    # ignored. Remember that file paths can also be encoded, let's suppose a doc
    # directory with the following files:
    #
    #   doc/
    #     components/.empty_directory
    #     README
    #     rdoc.rb.tt
    #     %app_name%.rb
    #
    # When invoked as:
    #
    #   directory "doc"
    #
    # It will create a doc directory in the destination with the following
    # files (assuming that the app_name is "blog"):
    #
    #   doc/
    #     components/
    #     README
    #     rdoc.rb
    #     blog.rb
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

    class Directory < Templater #:nodoc:

      def invoke!
        Dir[File.join(source, '**', '*')].each do |file_source|
          file_destination = File.join(relative_destination, file_source.gsub(source, ''))

          if File.directory?(file_source)
            base.empty_directory(file_destination, @log_status)
          elsif file_source !~ /\.empty_directory$/
            file_source.gsub!(base.source_root, '.')

            if file_source =~ /\.tt$/
              base.template(file_source, file_destination[0..-4], @log_status)
            else
              base.copy_file(file_source, file_destination, @log_status)
            end
          end
        end
      end

    end
  end
end
