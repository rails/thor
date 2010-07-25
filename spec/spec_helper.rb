$TESTING=true

$:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))
require 'thor'
require 'thor/group'
require 'stringio'

require 'rubygems'
require 'rdoc'
require 'diff/lcs' # You need diff/lcs installed to run specs (but not to run Thor).
require 'fakeweb'  # You need fakeweb installed to run specs (but not to run Thor).

# Set shell to basic
$0 = "thor"
$thor_runner = true
ARGV.clear
Thor::Base.shell = Thor::Shell::Basic

# Load fixtures
load File.join(File.dirname(__FILE__), "fixtures", "task.thor")
load File.join(File.dirname(__FILE__), "fixtures", "group.thor")
load File.join(File.dirname(__FILE__), "fixtures", "script.thor")
load File.join(File.dirname(__FILE__), "fixtures", "invoke.thor")

Kernel.module_eval do
  alias_method :must, :should
  alias_method :must_not, :should_not
  undef_method :should
  undef_method :should_not
end

Spec::Runner.configure do |config|
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
