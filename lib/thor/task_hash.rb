require 'thor/core_ext/ordered_hash'
require 'thor/task'

class Thor::TaskHash < Thor::CoreExt::OrderedHash
  def initialize(klass)
    super()
    @klass = klass
  end

  def each(local = false, &block)
    super() { |k, t| yield k, t.with_klass(@klass) }
    @klass.superclass.tasks.each { |k, t| yield k, t.with_klass(@klass) } unless local || @klass == Thor
  end

  def [](name)
    name = name.to_s

    if task = super(name)
      task.with_klass(@klass)
    elsif @klass != Thor && task = @klass.superclass.tasks[name]
      task.with_klass(@klass)
    else
      Thor::Task.dynamic(name, @klass)
    end
  end
end
