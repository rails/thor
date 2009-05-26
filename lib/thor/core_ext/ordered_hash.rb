class Thor #:nodoc:
  module CoreExt #:nodoc:

    # This class is based on the Ruby 1.9 ordered hashes.
    #
    # It keeps the semantics and most of the efficiency of normal hashes
    # while also keeping track of the order in which elements were set.
    #
    class OrderedHash #:nodoc:
      Node = Struct.new(:key, :value, :next, :prev)
      include Enumerable

      def initialize
        @hash = {}
      end

      # Called on clone. It gets all the notes from the cloned object, dup them
      # and assign the duped objects siblings.
      #
      def initialize_copy(other)
        @hash = {}

        array = []
        other.each do |key, value|
          array << (@hash[key] = Node.new(key, value))
        end

        array.each_with_index do |node, i|
          node.next = array[i + 1]
          node.prev = array[i - 1]
        end

        @first = array.first
        @last  = array.last
      end

      def [](key)
        @hash[key] && @hash[key].value
      end

      def []=(key, value)
        if old = @hash[key]
          node = old.dup
          node.value = value

          @first = node if @first == old
          @last  = node if @last  == old

          old.prev.next = node if old.prev
          old.next.prev = node if old.next
        else
          node = Node.new(key, value)

          if @first.nil?
            @first = @last = node
          else
            node.prev = @last
            @last.next = node
            @last = node
          end
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

      def keys
        self.map { |k, v| k }
      end

      def values
        self.map { |k, v| v }
      end

      def merge(other)
        new = clone
        other.each do |key, value|
          new[key] = value
        end
        new
      end

      def merge!(other)
        other.each do |key, value|
          self[key] = value
        end
        self
      end

      def to_a
        inject([]) do |array, (key, value)|
          array << [key, value]
          array
        end
      end

      def to_s
        to_a.inspect
      end
      alias :inspect :to_s
    end
  end
end
