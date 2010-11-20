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
    #   create_file "lib/fun_party.rb" do
    #     hostname = ask("What is the virtual hostname I should use?")
    #     "vhost.name = #{hostname}"
    #   end
    #
    #   create_file "config/apache.conf", "your apache config"
    #
    def create_file(destination, *args, &block)
      config = args.last.is_a?(Hash) ? args.pop : {}
      data = args.first
      action CreateFile.new(self, destination, block || data.to_s, config)
    end
    alias :add_file :create_file

    # AddFile is a subset of Template, which instead of rendering a file with
    # ERB, it gets the content from the user.
    #
    class CreateFile < EmptyDirectory #:nodoc:
      attr_reader :data

      def initialize(base, destination, data, config={})
        @data = data
        super(base, destination, config)
      end

      # Checks if the content of the file at the destination is identical to the rendered result.
      #
      # ==== Returns
      # Boolean:: true if it is identical, false otherwise.
      #
      def identical?
        exists? && File.binread(destination) == render
      end

      def invoke!
        invoke_with_conflict_check do
          FileUtils.mkdir_p(File.dirname(destination))
          File.open(destination, 'wb') { |f| f.write render }
        end
        given_destination
      end

      include CreationUtils

    end
  end
end
