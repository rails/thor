class Thor
  module LineEditor
    class Basic
      attr_reader :prompt, :options

      def self.available?
        true
      end

      def initialize(prompt, options)
        @prompt = prompt
        @options = options
      end

      def readline
        $stdout.print(prompt)
        $stdin.gets
      end
    end
  end
end
