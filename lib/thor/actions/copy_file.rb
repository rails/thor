require 'thor/actions/template'

class Thor
  module Actions

    # Copies the file from the relative source to the relative destination. If
    # the destination is not given it's assumed to be equal to the source.
    #
    # ==== Parameters
    # source<String>:: the relative path to the source root
    # destination<String>:: the relative path to the destination root
    # log_status<Boolean>:: if false, does not log the status. True by default.
    #
    # ==== Examples
    # copy_file "README", "doc/README"
    # copy_file "doc/README"
    #
    def copy_file(source, destination=nil, log_status=true)
      action CopyFile.new(self, source, destination || source, log_status)
    end

    class CopyFile < Template #:nodoc:

      def render
        @render ||= ::File.read(source)
      end

      def invoke!
        invoke_with_options!(base.options) do
          ::FileUtils.mkdir_p(::File.dirname(destination))
          ::FileUtils.cp_r(source, destination)
        end
      end

    end
  end
end
