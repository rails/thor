require 'fileutils'

Dir[File.join(File.dirname(__FILE__), "actions", "*.rb")].each do |action|
  require action
end

class Thor
  module Actions
    attr_accessor :behavior

    def initialize(args=[], options={}, config={})
      self.behavior = case config[:behavior]
        when :force
          options.merge!(:force => true)
          :invoke
        when :skip
          options.merge!(:skip => true)
          :invoke
        when :pretend
          options.merge!(:pretend => true)
          :invoke
        when :revoke
          :revoke
        else
          :invoke
      end

      super
    end

    protected

      # Wraps an action object and call it accordingly to the thor class behavior.
      #
      def action(instance)
        if behavior == :revoke
          instance.revoke!
        else
          instance.invoke!
        end
      end

      # Get the source root in the class. Raises an error if a source root is
      # not specified in the thor class.
      #
      def source_root 
        self.class.source_root
      rescue NoMethodError => e
        raise NoMethodError, "You have to specify the class method source_root in your thor class."
      end

      # Common methods that are delegated to the shell.
      #
      [:ask, :yes?, :no?, :say, :print_list, :print_table].each do |method|
        module_eval <<-METHOD, __FILE__, __LINE__
          def #{method}(*args)
            shell.#{method}(*args)
          end
        METHOD
      end

  end
end
