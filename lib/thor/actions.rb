require 'thor/shell/basic'

class Thor
  module Actions
    [:ask, :yes?, :no?, :say, :print_list, :print_table].each do |method|
      module_eval <<-METHOD, __FILE__, __LINE__
        def #{method}(*args)
          shell.#{method}(*args)
        end
      METHOD
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
