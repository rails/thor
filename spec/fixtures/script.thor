class MyScript < Thor
  group :script
  default_task :example_default_task

  map "-T" => :animal, ["-f", "--foo"] => :foo

  desc "zoo", "zoo around"
  def zoo
    true
  end

  desc "animal TYPE", "horse around"

  no_tasks do
    def this_is_not_a_task
    end
  end

  def animal(type)
    [type]
  end

  desc "foo BAR", <<END
do some fooing
  This is more info!
  Everyone likes more info!
END
  method_option :force, :type => :boolean, :description => "Very cool"
  def foo(bar)
    [bar, options]
  end

  desc "example_default_task", "example!"
  def example_default_task
    options.empty? ? "default task" : options
  end

  desc "call_myself_with_wrong_arity", "get the right error"
  def call_myself_with_wrong_arity
    call_myself_with_wrong_arity(4)
  end

  def call_unexistent_method
    boom!
  end

  def method_missing(meth, *args)
    if meth == :boom!
      super
    else
      [meth, args]
    end
  end

  private

    desc "what", "what"
    def what
    end
end

class MyChildScript < MyScript
  remove_task :bar

  method_options :force => :boolean, :param => :numeric
  def initialize(*args)
    super
  end

  desc "zoo", "zoo around"
  method_options :param => :required
  def zoo
    options
  end

  desc "animal TYPE", "horse around"
  def animal(type)
    [type, options]
  end
  method_option :other, :type => :string, :for => :animal
  desc "animal KIND", "fish around", :for => :animal

  desc "boom", "explodes everything"
  def boom
  end

  remove_task :boom, :undefine => true
end

module Scripts
  class MyGrandChildScript < MyChildScript
    argument :accessor, :type => :string
    class_options :force => :optional
    method_option :new_option, :type => :string, :for => :example_default_task

    def zoo
      self.accessor
    end
  end
end
