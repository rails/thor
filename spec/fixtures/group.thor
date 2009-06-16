class MyCounter < Thor::Group
  include Thor::Actions

  def self.source_root
    File.join(File.dirname(__FILE__))
  end

  argument :first,     :type => :numeric
  argument :second,    :type => :numeric, :default => 2
  class_option :third, :type => :numeric, :desc => "The third argument.", :default => 3

  desc <<-FOO
Description:
  This generator run three tasks: one, two and three.
FOO

  def one
    first
  end

  def two
    second
  end

  def three
    options[:third]
  end
end

class BrokenCounter < MyCounter
  namespace "app:broken:counter"
  class_option :fail, :type => :boolean, :default => false

  def one
    options[:first]
  end

  def four
    respond_to?(:fail)
  end

  def five
    options[:fail] ? this_method_does_not_exist : 5
  end
end

class WhinyGenerator < Thor::Group
  def wrong_arity(required)
  end
end
