# module: random

class Amazing < Thor
  include Thor::Actions

  def self.source_root
    File.join(File.dirname(__FILE__), "spec", "fixtures")
  end

  desc "describe NAME", "say that someone is amazing"
  method_options :forcefully => :boolean
  def describe(name)
    ret = "#{name} is amazing"
    puts options[:forcefully] ? ret.upcase : ret
  end

  desc "hello", "say hello"
  def hello
    puts "Hello"
  end

  desc "create", "create a file"
  def create
    create_file "task.thor", Time.now.utc.to_s
  end
end
