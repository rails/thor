# module: random

class Amazing < Thor
  def self.exit_on_failure?
    false
  end

  desc "describe NAME", "say that someone is amazing"
  method_options :forcefully => :boolean
  def describe(name, opts)
    ret = "#{name} is amazing"
    puts opts["forcefully"] ? ret.upcase : ret
  end
end
