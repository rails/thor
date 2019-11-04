#!/usr/bin/ruby

$VERBOSE = true

require 'thor'

class Test < Thor
end

Test.start(ARGV)
