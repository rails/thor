$TESTING=true

require 'simplecov'
SimpleCov.start do
  add_group 'Libraries', 'lib'
  add_group 'Specs', 'spec'
end

$:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))
require 'thor'
require 'thor/group'
require 'thor/wrapper'
require 'stringio'

require 'rdoc'
require 'rspec'
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
load File.join(File.dirname(__FILE__), "fixtures", "wrapper.thor")

# Wrap the backquote method: for testing Thor::Wrapper
class Object
  alias_method :old_backquote, :`
  def `(cmd)
    case cmd
    when "which #{WRAPPED_COMMAND.inspect}" # Issued by Thor::Wrapper when locating parent
      WRAPPED_PATH
    when "#{WRAPPED_COMMAND} help" # Issued by Thor::Wrapper when answering a help command
      <<END
Tasks:
  textmate help [TASK]      # Describe available tasks or one specific task
  textmate install NAME     # Install a bundle. Source must be one of trunk, review, or github. If multiple gems with...
  textmate list [SEARCH]    # lists all the bundles installed locally
  textmate reload           # Reloads TextMate Bundles
  textmate search [SEARCH]  # Lists all the matching remote bundles
  textmate uninstall NAME   # uninstall a bundle

END
    when "#{WRAPPED_COMMAND} foo bar" # Issued by Thor::Wrapper during test of Thor::Wrapper#wrap and Thor::Wrapper.wrap
      "burble\nburble\n"
    else # Some other :` request; pass through unchanged
      old_backquote(cmd)
    end
  end
end

RSpec.configure do |config|
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
