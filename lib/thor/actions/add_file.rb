require 'thor/actions/template'

class Thor
  module Actions

    # Create a new file relative to the destination root with the given data,
    # which is the return value of a block or a data string.
    #
    # ==== Parameters
    # destination<String>:: the relative path to the destination root.
    # data<String|NilClass>:: the data to append to the file.
    # log_status<Boolean>:: if false, does not log the status. True by default.
    #
    # ==== Examples
    #
    #   add_file "lib/fun_party.rb" do
    #     hostname = ask("What is the virtual hostname I should use?")
    #     "vhost.name = #{hostname}"
    #   end
    #
    #   add_file "config/apach.conf", "your apache config"
    #
    def add_file(destination, data=nil, log_status=true, &block)
      action AddFile.new(self, destination, data, log_status, &block)
    end
    alias :file :add_file

    # AddFile is a subset of Template, which instead of rendering a file with
    # ERB, it gets the content from the user.
    #
    class AddFile < Template #:nodoc:
      attr_reader :data

      def initialize(base, destination, data, log_status, &block)
        super(base, nil, destination, log_status)
        @data = block || data.to_s
      end

      def render
        @render ||= if data.is_a?(Proc)
          data.call
        else
          data
        end
      end
    end
  end
end
