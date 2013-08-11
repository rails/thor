require 'readline' rescue nil

class Thor
  module LineEditor
    class Readline < Basic
      def self.available?
        Kernel.const_defined?(:Readline)
      end

      def readline
        ::Readline.readline(prompt, add_to_history?)
      end

      private

      def add_to_history?
        options.fetch(:add_to_history, true)
      end
    end
  end
end
