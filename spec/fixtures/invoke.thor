class A < Thor
  include Thor::Actions

  def one
    p 1
    invoke :two
    invoke :three
  end

  def two
    p 2
    invoke :three
  end

  def three
    p 3
  end
end

class B < Thor
  argument :last_name, :type => :string

  def one(first_name)
    puts "#{last_name}, #{first_name}"
  end

  def two
    options
  end

  def three
    dump_config
  end
end

class C < Thor::Group
  include Thor::Actions

  def one
    dump_config
  end
end
