class MyScript < Thor
  group :script
  default_task :example_default_task

  map "-T" => :animal, ["-f", "--foo"] => :foo

  desc "zoo", "zoo around"
  def zoo
    true
  end

  desc "animal TYPE", "horse around"
  def animal(type)
    [type]
  end

  desc "foo BAR", <<END
do some fooing
  This is more info!
  Everyone likes more info!
END
  option :force, :type => :boolean, :description => "Very cool"
  def foo(bar)
    [bar, options]
  end

  desc "example_default_task", "example!"
  def example_default_task
    "default task"
  end

  desc "bar BAZ BAT", "do some barring"
  option :option1, :type => :string, :default => "boom"
  def bar(baz, bat)
    [baz, bat, options]
  end

  desc "baz BAT", "do some bazzing"
  method_options :option1 => :optional
  def baz(bat)
    [bat, options]
  end

  desc "call_myself_with_wrong_arity", "get the right error"
  def call_myself_with_wrong_arity
    call_myself_with_wrong_arity(4)
  end

  def method_missing(meth, *args)
    [meth, args]
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
  option :other, :type => :string, :for => :animal
  desc "animal KIND", "fish around", :for => :animal

  desc "boom", "explodes everything"
  def boom
  end

  remove_task :boom, :undefine => true
end

module Scripts
  class MyGrandChildScript < MyChildScript
    default_options :force => :optional, :param => :required
    option :new_option, :type => :string, :for => :bar
  end
end
