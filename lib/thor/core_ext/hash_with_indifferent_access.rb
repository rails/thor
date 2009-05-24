class Thor
  module CoreExt
    class HashWithIndifferentAccess < ::Hash
      def initialize(hash)
        super()
        update hash
      end
      
      def [](key)
        super convert_key(key)
      end
      
      def values_at(*indices)
        indices.collect { |key| self[convert_key(key)] }
      end
      
      protected
        def convert_key(key)
          key.kind_of?(Symbol) ? key.to_s : key
        end
        
        # Magic predicates. For instance:
        #   options.force? # => !!options['force']
        def method_missing(method, *args, &block)
          method = method.to_s
          if method =~ /^(\w+)=$/ 
            self[$1] = args.first
          elsif method =~ /^(\w+)\?$/
            !!self[$1]
          else 
            self[method]
          end
        end
    end
  end
end
