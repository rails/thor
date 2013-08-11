class Thor
  module LineEditor
    class Basic
      attr_reader :prompt

      def self.available?
        true
      end

      def initialize(prompt)
        @prompt = prompt
      end

      def readline
        $stdout.print(prompt)
        $stdin.gets
      end
    end
  end
end
