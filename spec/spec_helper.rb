$TESTING=true
$:.push File.join(File.dirname(__FILE__), '..', 'lib')

module Spec::Expectations::ObjectExpectations
  alias_method :must, :should
  alias_method :must_not, :should_not
  undef_method :should
  undef_method :should_not
end

class StdOutCapturer
  attr_reader :output

  def initialize
    @output = ""
  end

  def self.call_func
    begin
      old_out = $stdout
      output = new
      $stdout = output
      yield
    ensure
      $stdout = old_out
    end
    output.output
  end

  def write(s)
    @output += s
  end
end

module Spec
  module Mocks
    module StubAllInstances
      class AllInstancesStubber
      
        def initialize(target)
          @target = target
          @stubbed_methods = []
        end
        
        def stub(message)
          stubber = MethodStubber.new(target, message)
          stubber.add_stub
          register_stub(stubber)
          stubber
        end
        
        alias_method :stub!, :stub
        
        def reset
          stubbed_methods.each { |object| object.reset! }
        end
        
      private
        
        attr_reader :stubbed_methods
        attr_reader :target
        
        def register_stub(stubber)
          $rspec_mocks.add(stubber)
          @stubbed_methods << stubber
        end
      end      
      
      module Methods
        # See the documentation under Spec::Mocks::StubAllInstances
        def stub_all_instances(sym=nil, &block)
          if block
            block.call(__all_instances_stubber__)
          else
            __all_instances_stubber__.stub(sym)
          end
        end
        
        def __rspec_clear_instances__
          __all_instances_stubber__.reset
        end
        
      private

        def __all_instances_stubber__
          @__all_instances_stubber__ ||= AllInstancesStubber.new(self)
        end
      end
    end
    
    class MethodStubber
      
      def initialize(target, message)
        @target = target
        @message = message
      end
      
      attr_reader :target
      attr_reader :message
      
      def add_stub
        add_stub_with_value(nil)
      end
      
      def and_return(value)
        add_stub_with_value(value)
      end
      
      def and_raise(*raise_params)
        add_stub_with_error(*raise_params)
      end
      
      def reset!
        # We need these vars as locals for scope inside the class_eval
        message, munged_sym = self.message, self.munged_sym
        
        target.class_eval do
          if method_defined?(munged_sym)
            alias_method message, munged_sym
            undef_method munged_sym
          end
        end
      end
      
      alias_method :rspec_reset, :reset!
      
      def verified?
        @verified
      end
      
      def rspec_verify
        @verified = true
      end
      
      def munged_sym
        @munged_sym ||= "__rspec_proxy_all_instances_#{message}".to_sym
      end
      
    private
      
      def add_stub_with_value(value)
        define_stub { value }
      end
      
      def add_stub_with_error(*raise_params)
        define_stub { raise(*raise_params) }
      end
      
      # We take a lambda which wraps the value (instead of the direct value)
      # since we may have a raise statement as the value of the method call
      def define_stub(&lambda_wrapping_value)
        store_current_instance_method do |message|
          target.class_eval do
            define_method(message) { lambda_wrapping_value.call }
          end
        end
      end
      
      def method_present?
        instance_methods.include?(message.to_s)
      end
      
      def instance_methods
        target.instance_methods
      end
      
      def store_current_instance_method
        # need the local vars for scoping
        message = self.message
        munged_sym = self.munged_sym
        
        if method_present?
          target.class_eval do
            alias_method munged_sym, message
          end
        end
        
        yield(message)
      end
    end    
  end
end

Spec::Runner.configure do |config|
  def stdout_from(&blk)
    StdOutCapturer.call_func(&blk)
  end
end