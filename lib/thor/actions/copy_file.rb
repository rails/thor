require 'thor/actions/templater'

class Thor
  module Actions

    # Copies the file from the relative source to the relative destination. If
    # the destination is not given it's assumed to be equal to the source.
    #
    # ==== Parameters
    # source<String>:: the relative path to the source root
    # destination<String>:: the relative path to the destination root
    #
    # ==== Examples
    # copy_file "README", "doc/README"
    # copy_file "doc/README"
    #
    def copy_file(source, destination=nil)
      action CopyFile.new(self, source, destination || source)
    end

    class CopyFile < Templater #:nodoc:

      def render
        ::File.read(source)
      end

      def exists?
        ::File.exists?(destination)
      end

      def identical?
        exists? && ::FileUtils.identical?(source, destination)
      end

      def invoke!
        invoke_with_options!(base.options) do
          ::FileUtils.mkdir_p(::File.dirname(destination))
          ::FileUtils.cp_r(source, destination)
        end
      end

      def revoke!
        say_status :deleted, :green
        ::FileUtils.rm_r(destination, :force => true)
      end

    end
  end
end
