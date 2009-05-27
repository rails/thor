$TESTING=true

$:.push File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'thor'
require 'stringio'
require 'rubygems'

# Load fixtures
load File.join(File.dirname(__FILE__), "fixtures", "task.thor")
load File.join(File.dirname(__FILE__), "fixtures", "script.thor")

undefinable = if defined?(Spec::Expectations::ObjectExpectations) # rspec <= 1.2.0
  Spec::Expectations::ObjectExpectations
else
  Kernel
end

undefinable.module_eval do
  alias_method :must, :should
  alias_method :must_not, :should_not
  undef_method :should
  undef_method :should_not
end

Spec::Runner.configure do |config|
  config.mock_with :rr

  def capture(stream)
    begin
      stream = stream.to_s
      eval "$#{stream} = StringIO.new"
      yield
      result = eval("$#{stream}").string
    ensure 
      eval("$#{stream} = #{stream.upcase}")
    end

    result
  end

  alias silence capture
end
