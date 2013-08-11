require 'readline' rescue nil

class Thor
  module LineEditor
    class Readline < Basic
      def self.available?
        Kernel.const_defined?(:Readline)
      end

      def readline
        ::Readline.completion_proc = completion_proc
        ::Readline.readline(prompt, add_to_history?)
      end

      private

      def add_to_history?
        options.fetch(:add_to_history, true)
      end

      def completion_proc
        if completion_options.any?
          Proc.new do |text|
            completion_options.select { |option| option.start_with?(text) }
          end
        end
      end

      def completion_options
        options.fetch(:limited_to, [])
      end
    end
  end
end
