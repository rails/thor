$TESTING=true

$:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))
require 'thor'
require 'stringio'

require 'rubygems'
require 'rr'
require 'diff/lcs' # You need diff/lcs installed to run specs (but not to run Thor).

# Load fixtures
load File.join(File.dirname(__FILE__), "fixtures", "task.thor")
load File.join(File.dirname(__FILE__), "fixtures", "group.thor")
load File.join(File.dirname(__FILE__), "fixtures", "script.thor")
load File.join(File.dirname(__FILE__), "fixtures", "invoke.thor")

# Set shell to basic
Thor::Base.shell = Thor::Shell::Basic

Kernel.module_eval do
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

  def source_root
    File.join(File.dirname(__FILE__), 'fixtures')
  end

  def destination_root
    File.join(File.dirname(__FILE__), 'sandbox')
  end

  alias :silence :capture
end
