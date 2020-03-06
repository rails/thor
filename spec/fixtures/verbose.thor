#!/usr/bin/ruby

$VERBOSE = true

require 'thor'

class Test < Thor
  def self.exit_on_failure?
    true
  end
end

Test.start(ARGV)
