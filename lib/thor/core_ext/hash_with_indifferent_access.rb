class Thor
  module CoreExt

    # A hash with indifferent access and magic predicates.
    #
    #   hash = Thor::CoreExt::HashWithIndifferentAccess.new 'foo' => 'bar', 'baz' => 'bee', 'force' => true
    #
    #   hash[:foo]  #=> 'bar'
    #   hash['foo'] #=> 'bar'
    #   hash.foo?   #=> true
    #
    class HashWithIndifferentAccess < ::Hash

      def initialize(hash)
        super()

        hash.each do |key, value|
          if key.is_a?(Symbol)
            self[key.to_s] = value
          else
            self[key] = value
          end
        end
      end

      def [](key)
        super(convert_key(key))
      end

      def delete(key)
        super(convert_key(key))
      end

      def values_at(*indices)
        indices.collect { |key| self[convert_key(key)] }
      end

      protected

        def convert_key(key)
          key.is_a?(Symbol) ? key.to_s : key
        end

        # Magic predicates. For instance:
        #
        #   options.force? # => !!options['force']
        #
        def method_missing(method, *args, &block)
          method = method.to_s
          if method =~ /^(\w+)\?$/
            !!self[$1]
          else 
            self[method]
          end
        end

    end
  end
end
