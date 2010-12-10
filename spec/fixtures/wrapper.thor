#!/usr/bin/env ruby

require 'rubygems'
require 'thor'
require 'thor/wrapper'

# For use in testing
WRAPPED_COMMAND = 'textmate'
WRAPPED_PATH = '/usr/bin/textmate'

class Wrapping < Thor::Wrapper
  wraps WRAPPED_COMMAND
     
  desc "bar", "Do cool stuff"
  def bar
	puts "plugh"
  end

  desc "update", "Hijack the update command"
  def update
    puts "Oh no, you didn't"
  end
end

if __FILE__ == $0
  Wrapping.start
end
