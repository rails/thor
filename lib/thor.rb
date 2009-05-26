$:.unshift File.expand_path(File.dirname(__FILE__))
require 'thor/base'

class Thor
  include Thor::Base
  attr_accessor :options

  map ["-h", "-?", "--help", "-D"] => :help

  desc "help [TASK]", "describe available tasks or one specific task"
  def help(task = nil)
    if task
      if task.include? ?:
        task = self.class[task]
        namespace = true
      else
        task = self.class[task]
      end

      puts task.formatted_usage(self, namespace)
      puts task.description
    else
      puts "Options"
      puts "-------"
      self.class.all_tasks.each do |_, task|
        format = "%-" + (self.class.maxima.usage + self.class.maxima.opt + 4).to_s + "s"
        print format % ("#{task.formatted_usage(self, false)}")
        puts  task.description.split("\n").first
      end
    end
  end
end
