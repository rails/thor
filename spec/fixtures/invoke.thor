class A < Thor
  include Thor::Actions

  desc "one", "invoke one"
  def one
    p 1
    invoke :two
    invoke :three
  end

  desc "two", "invoke two"
  def two
    p 2
    invoke :three
  end

  desc "three", "invoke three"
  def three
    p 3
  end

  desc "four", "invoke four"
  def four
    p 4
    invoke "d:five"
  end

  desc "five N", "check if number is equal 5"
  def five(number)
    number == 5
  end

  desc "invoker", "invoke a b task"
  def invoker(*args)
    invoke :b, :one, ["José"]
  end
end

class B < Thor
  class_option :last_name, :type => :string

  desc "one FIRST_NAME", "invoke one"
  def one(first_name)
    "#{options.last_name}, #{first_name}"
  end

  desc "two", "invoke two"
  def two
    options
  end

  desc "three", "invoke three"
  def three
    self
  end
end

class C < Thor::Group
  include Thor::Actions

  def one
    p 1
  end

  def two
    p 2
  end

  def three
    p 3
  end
end

class D < Thor
  desc "one", "invoke one"
  def one
    p 1
    invoke "a:two"
    invoke "a:three"
    invoke "a:four"
    invoke "d:five"
  end

  desc "five", "invoke five"
  def five
    p 5
  end
end

