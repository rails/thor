# module: random

class Amazing < Thor
  desc "describe NAME", "say that someone is amazing"
  method_options :forcefully => :boolean
  def describe(name)
    ret = "#{name} is amazing"
    puts options.forcefully?? ret.upcase : ret
  end
  
  desc "hello", "say hello"
  def hello
    puts "Hello"
  end
end
