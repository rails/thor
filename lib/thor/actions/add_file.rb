require 'thor/actions/template'

class Thor
  module Actions

    # Create a new file relative to the destination root with the given data,
    # which is the return value of a block or a data string.
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
    def add_file(destination, data=nil, &block)
      action AddFile.new(self, destination, data, &block)
    end
    alias :file :add_file

    # AddFile is a subset of Template, which instead of rendering a file with
    # ERB, it gets the content from the user.
    #
    class AddFile < Template #:nodoc:
      attr_reader :data

      def initialize(base, destination, data, &block)
        @data = block || data.to_s
        super(base, nil, destination)
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
