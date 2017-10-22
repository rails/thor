Bundler.require :development, :default

class Help < Thor

  desc :bugs, "ALL THE BUGZ!"
  option "--not_help", :type => :boolean
  def bugs
    puts "Invoked!"
  end

end

Help.start(ARGV)
