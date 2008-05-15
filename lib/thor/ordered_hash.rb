class Thor
  # This class is based on the Ruby 1.9 ordered hashes.
  # It keeps the semantics and most of the efficiency of normal hashes
  # while also keeping track of the order in which elements were set.
  class OrderedHash
    Node = Struct.new(:key, :value, :next, :prev)
    include Enumerable

    def initialize
      @hash = {}
    end

    def initialize_copy(other)
      @hash = other.instance_variable_get('@hash').clone
    end

    def [](key)
      @hash[key] && @hash[key].value
    end

    def []=(key, value)
      node = Node.new(key, value)

      if old = @hash[key]
        if old.prev
          old.prev.next = old.next
        else # old is @first and @last
          @first = @last = nil
        end
      end

      if @first.nil?
        @first = @last = node
      else
        node.prev = @last
        @last.next = node
        @last = node
      end

      @hash[key] = node
      value
    end

    def each
      return unless @first
      yield [@first.key, @first.value]
      node = @first
      yield [node.key, node.value] while node = node.next
      self
    end

    def values
      self.map { |k, v| v }
    end

    def +(other)
      new = clone
      other.each do |key, value|
        new[key] = value unless self[key]
      end
      new
    end
  end
end
