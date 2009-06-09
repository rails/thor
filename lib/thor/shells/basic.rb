class Thor
  module Shells
    class Basic
      def self.ask(sentence)
        say("#{sentence} ", false)
        $stdin.gets.strip
      end

      def self.say(sentence, new_line=true)
        if new_line
          $stdout.puts sentence
        else
          $stdout.print sentence
        end
      end

      def self.yes?(sentence)
        ["y", "yes"].include?(ask(sentence).downcase)
      end

      def self.no?(sentence)
        !yes?(sentence)
      end
    end
  end
end
