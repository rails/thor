$TESTING=true
$:.push File.join(File.dirname(__FILE__), '..', 'lib')

module Spec::Expectations::ObjectExpectations
  alias_method :must, :should
  alias_method :must_not, :should_not
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
