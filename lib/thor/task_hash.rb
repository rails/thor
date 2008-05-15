require 'thor/ordered_hash'

class Thor::TaskHash < Thor::OrderedHash
  def initialize(klass)
    super()
    @klass = klass
  end

  def each(&block)
    super(&block)
    @klass.superclass.tasks.each(&block) unless @klass == Thor
  end

  def [](name)
    task = super(name)
    task.with_klass(@klass) if task
  end
end
