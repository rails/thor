require 'thor/ordered_hash'
require 'thor/task'

class Thor::TaskHash < Thor::OrderedHash
  def initialize(klass)
    super()
    @klass = klass
  end

  def each(local = false, &block)
    super() { |k, t| yield k, t.with_klass(@klass) }
    @klass.superclass.tasks.each { |k, t| yield k, t.with_klass(@klass) } unless local || @klass == Thor
  end

  def [](name)
    if task = super(name) || (@klass == Thor && @klass.superclass.tasks[name])
      return task.with_klass(@klass)
    end

    Thor::Task.dynamic(name, @klass)
  end
end
