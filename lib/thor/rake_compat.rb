begin
  require 'rake'
rescue LoadError
  require 'rubygems'
  gem 'rake'
  require 'rake'
end

class Thor
  module RakeCompat
    def self.rake_classes
      @rake_classes ||= []
    end

    def self.included(base)
      self.rake_classes << base
    end
  end
end

class Object
  alias :rake_task :task
  alias :rake_namespace :namespace

  def task(*args, &block)
    task = rake_task(*args, &block)

    if klass = Thor::RakeCompat.rake_classes.last
      non_namespaced_name = task.name.split(':').last

      description = non_namespaced_name
      description << task.arg_names.map{ |n| n.to_s.upcase }.join(' ')
      description.strip!

      klass.desc description, task.comment || non_namespaced_name
      klass.class_eval <<-METHOD
        def #{non_namespaced_name}(#{task.arg_names.join(', ')})
          Rake::Task[#{task.name.to_sym.inspect}].invoke(#{task.arg_names.join(', ')})
        end
      METHOD
    end

    task
  end

  def namespace(name, &block)
    if klass = Thor::RakeCompat.rake_classes.last
      const_name = name.to_s.capitalize.to_sym
      klass.const_set(const_name, Class.new(Thor))
      new_klass = klass.const_get(const_name)
      Thor::RakeCompat.rake_classes << new_klass
    end

    rake_namespace(name, &block)
    Thor::RakeCompat.rake_classes.pop
  end
end
