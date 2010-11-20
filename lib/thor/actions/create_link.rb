require 'thor/actions/empty_directory'
require 'thor/actions/creation_utils'

class Thor
  module Actions

    # Create a new file relative to the destination root with the given data,
    # which is the return value of a block or a data string.
    #
    # ==== Parameters
    # destination<String>:: the relative path to the destination root.
    # data<String|NilClass>:: the data to append to the file.
    # config<Hash>:: give :verbose => false to not log the status.
    #
    # ==== Examples
    #
    #   create_link "config/apache.conf", "/etc/apache.conf"
    #
    def create_link(destination, *args, &block)
      config = args.last.is_a?(Hash) ? args.pop : {}
      source = args.first
      action CreateLink.new(self, destination, source, config)
    end
    alias :add_link :create_link

    # AddFile is a subset of Template, which instead of rendering a file with
    # ERB, it gets the content from the user.
    #
    class CreateLink < EmptyDirectory #:nodoc:
      attr_reader :data

      def initialize(base, destination, data, config={})
        @data = data
        super(base, destination, config)
      end

      def invoke!
        invoke_with_conflict_check do
          FileUtils.mkdir_p(File.dirname(destination))
          # Create a symlink by default
          config[:symbolic] ||= true
          if config[:symbolic]
            File.symlink(render, destination)
          else
            File.link(render, destination)
          end
        end
        given_destination
      end

      include CreationUtils

    end
  end
end
