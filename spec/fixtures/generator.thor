class MyCounter < Thor::Generator
  argument :first,  :type => :numeric
  argument :second, :type => :numeric, :default => 2 # default is ignored
  option :third,    :type => :numeric

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
  option :fail, :type => :boolean, :default => false

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

class WhinyGenerator < Thor::Generator
  def wrong_arity(required)
  end
end
