require 'readline' rescue nil

class Thor
  module LineEditor
    def self.readline(prompt)
      if defined? Readline
        Readline.readline(prompt)
      else
        $stdout.print(prompt)
        $stdin.gets
      end
    end
  end
end
