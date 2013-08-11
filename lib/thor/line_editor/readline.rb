require 'readline' rescue nil

class Thor
  module LineEditor
    class Readline < Basic
      def self.available?
        Kernel.const_defined?(:Readline)
      end

      def readline
        ::Readline.readline(prompt)
      end
    end
  end
end
