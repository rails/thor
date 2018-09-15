require "thor"

class MySimpleThor2 < Thor2
  class_option "verbose",   :type => :boolean
  class_option "mode",      :type => :string

  desc "checked", "a command with checked"
  def checked(*args)
    puts [options, args].inspect
    [options, args]
  end
end

MySimpleThor2.start(ARGV)

