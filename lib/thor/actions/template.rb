require 'thor/actions/templater'
require 'erb'

class Thor
  module Actions

    # Gets an ERB template at the relative source, executes it and makes a copy
    # at the relative destination. If the destination is not given it's assumed
    # to be equal to the source.
    #
    # ==== Parameters
    # source<String>:: the relative path to the source root
    # destination<String>:: the relative path to the destination root
    #
    # ==== Examples
    # template "README", "doc/README"
    # template "doc/README"
    #
    def template(source, destination=nil, log_status=true)
      action Template.new(self, source, destination || source, log_status)
    end

    class Template < Templater #:nodoc:

      def render
        @render ||= begin
          context = base.instance_eval('binding')
          ERB.new(::File.read(source), nil, '-').result(context)
        end
      end

      def exists?
        ::File.exists?(destination)
      end

      def identical?
        exists? && ::File.read(destination) == render
      end

      def invoke!
        invoke_with_options!(base.options) do
          ::FileUtils.mkdir_p(::File.dirname(destination))
          ::File.open(destination, 'w'){ |f| f.write render }
        end
      end

      def revoke!
        say_status :deleted, :green
        ::FileUtils.rm(destination, :force => true)
      end

    end
  end
end
