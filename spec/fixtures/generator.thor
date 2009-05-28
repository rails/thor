class MyCounter < Thor::Generator
  argument :first,  :type => :numeric
  argument :second, :type => :numeric
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
  def one
    options[:first]
  end

  def fourth
    respond_to?(:three)
  end
end
