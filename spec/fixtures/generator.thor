class MyScaffold < Thor::Generator
  option :third, :type => :numeric

  def one
    1
  end

  def two
    2
  end

  def three
    3
  end
end
