require "thor"

class ExitStatus < Thor
  def self.exit_on_failure?
    true
  end

  desc "error", "exit with a planned error"
  def error
    raise Thor::Error.new("planned error")
  end

  desc "ok", "exit with no error"
  def ok
  end
end

ExitStatus.start(ARGV)

