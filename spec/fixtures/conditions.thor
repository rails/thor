class Conditional < Thor::Group
  class_option :test_framework, :type => :string
  class_option :with_dispatchers, :type => :boolean, :default => false

  conditions :test_framework => :rspec
  def one
    1
  end

  conditions :test_framework => [:rspec, :remarkable]
  def two
    2
  end

  conditions :test_framework => /remarkable/
  def three
    3
  end

  conditions :with_dispatchers => true
  def four
    4
  end
end

class Simplified < Conditional
  conditions :test_framework => [:rspec, :remarkable], :for => :one
  remove_conditions :with_dispatchers, :for => :four
end
