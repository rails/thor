class IgnoreClassOptions < Thor
  class_option :fruit, :aliases => "-f", :type => :string, :enum => %w(apple banana), :required => true
  class_option :cheese, :aliases => "-c", :type => :string, :enum => %w(pepperjack provlone), :required => true

  desc "snack", "test"
  method_option :vegetable, :aliases => "-v", :type => :string
  def snack
    options
  end

  desc "shake", "test"
  method_option :milk, :aliases => "-k", :type => :numeric
  ignore_class_options [:cheese]
  def shake
    options
  end
end
