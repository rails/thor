Dir[File.join(File.dirname(__FILE__), "tasks", "*.rb")].each do |task|
  require task
end
