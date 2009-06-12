# module: random

class Amazing < Thor
  include Actions

  def source_root
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

  desc "copy", "copy a file"
  def copy
    copy_file "task.thor", "foo.thor"
  end
end
