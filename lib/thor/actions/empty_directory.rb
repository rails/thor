require 'thor/actions/templater'

class Thor
  module Actions

    # Creates an empty directory.
    #
    # ==== Parameters
    # destination<String>:: the relative path to the destination root
    # log_status<Boolean>:: if false, does not log the status. True by default.
    #
    # ==== Examples
    # empty_directory "doc"
    #
    def empty_directory(destination, log_status=true)
      action EmptyDirectory.new(self, nil, destination, log_status)
    end

    class EmptyDirectory < Templater #:nodoc:

      def exists?
        ::File.exists?(destination)
      end

      def identical?
        exists?
      end

      def invoke!
        invoke_with_options!(base.options) do
          ::FileUtils.mkdir_p(destination)
        end
      end

      def revoke!
        say_status :deleted, :green
        ::FileUtils.rm_rf(destination) unless pretend?
      end

    end
  end
end
