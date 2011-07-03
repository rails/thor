# enconding: utf-8
$:.unshift File.expand_path("../lib", __FILE__)

require 'thor/rake_compat'

class Default < Thor
  include Thor::RakeCompat

  desc "spec", "run the specs"
  def spec
    exec "rspec -cfs spec"
  end
end
