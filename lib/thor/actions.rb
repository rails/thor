require 'thor/shell/basic'

class Thor
  module Actions
    def ask(*args)
      shell.ask(*args)
    end

    def yes?(*args)
      shell.yes?(*args)
    end

    def no?(*args)
      shell.no?(*args)
    end

    def say(*args)
      shell.say(*args)
    end
  end

  module Base
    include Actions

    def self.shell=(klass)
      @shell = klass
    end

    def self.shell
      @shell || Thor::Shell::Basic
    end
  end
end
