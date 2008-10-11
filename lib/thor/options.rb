# This is a modified version of Daniel Berger's Getopt::Long class,
# licensed under Ruby's license.

class Thor
  class Options
    class Error < StandardError; end
    
    # simple Hash with indifferent access
    class Hash < ::Hash
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
          method.to_s =~ /^(\w+)\?$/ ? !!self[$1] : super
        end
    end

    NUMERIC     = /(\d*\.\d+|\d+)/
    LONG_RE     = /^(--\w+[-\w+]*)$/
    SHORT_RE    = /^(-[a-z])$/i
    EQ_RE       = /^(--\w+[-\w+]*|-[a-z])=(.*)$/i
    SHORT_SQ_RE = /^-([a-z]{2,})$/i # Allow either -x -v or -xv style for single char args
    SHORT_NUM   = /^(-[a-z])#{NUMERIC}$/i
    
    attr_reader :leading_non_opts, :trailing_non_opts
    
    def non_opts
      leading_non_opts + trailing_non_opts
    end

    # Takes an array of switches. Each array consists of up to three
    # elements that indicate the name and type of switch. Returns a hash
    # containing each switch name, minus the '-', as a key. The value
    # for each key depends on the type of switch and/or the value provided
    # by the user.
    #
    # The long switch _must_ be provided. The short switch defaults to the
    # first letter of the short switch. The default type is :boolean.
    #
    # Example:
    #
    #   opts = Thor::Options.new(
    #      "--debug" => true,
    #      ["--verbose", "-v"] => true,
    #      ["--level", "-l"] => :numeric
    #   ).parse(args)
    #
    def initialize(switches)
      @defaults = {}
      @shorts = {}
      
      @leading_non_opts, @trailing_non_opts = [], []

      @switches = switches.inject({}) do |mem, (name, type)|
        if name.is_a?(Array)
          name, *shorts = name
        else
          name = name.to_s
          shorts = []
        end
        # we need both nice and dasherized form of switch name
        if name.index('-') == 0
          nice_name = undasherize name
        else
          nice_name = name
          name = dasherize name
        end
        # if there are no shortcuts specified, generate one using the first character
        shorts << "-" + nice_name[0,1] if shorts.empty? and nice_name.length > 1
        shorts.each { |short| @shorts[short] = name }
        
        # normalize type
        case type
        when TrueClass then type = :boolean
        when String
          @defaults[nice_name] = type
          type = :optional
        when Numeric
          @defaults[nice_name] = type
          type = :numeric
        end
        
        mem[name] = type
        mem
      end
      
      # remove shortcuts that happen to coincide with any of the main switches
      @shorts.keys.each do |short|
        @shorts.delete(short) if @switches.key?(short)
      end
    end

    def parse(args, skip_leading_non_opts = true)
      @args = args
      # start with Thor::Options::Hash pre-filled with defaults
      hash = Hash.new @defaults
      
      @leading_non_opts = []
      if skip_leading_non_opts
        @leading_non_opts << shift until current_is_option? || @args.empty?
      end

      while current_is_option?
        case shift
        when SHORT_SQ_RE
          unshift $1.split('').map { |f| "-#{f}" }
          next
        when EQ_RE, SHORT_NUM
          unshift $2
          switch = $1
        when LONG_RE, SHORT_RE
          switch = $1
        end
        
        switch    = normalize_switch(switch)
        nice_name = undasherize(switch)
        type      = switch_type(switch)
        
        case type
        when :required
          assert_value!(switch)
          raise Error, "cannot pass switch '#{peek}' as an argument" if valid?(peek)
          hash[nice_name] = shift
        when :optional
          hash[nice_name] = peek.nil? || valid?(peek) || shift
        when :boolean
          hash[nice_name] = true
        when :numeric
          assert_value!(switch)
          unless peek =~ NUMERIC and $& == peek
            raise Error, "expected numeric value for '#{switch}'; got #{peek.inspect}"
          end
          hash[nice_name] = $&.index('.') ? shift.to_f : shift.to_i
        end
      end
      
      @trailing_non_opts = @args

      check_required! hash
      hash.freeze
      hash
    end
    
    def formatted_usage
      return "" if @switches.empty?
      @switches.map do |opt, type|
        case type
        when :boolean
          "[#{opt}]"
        when :required
          opt + "=" + opt.gsub(/\-/, "").upcase
        else
          sample = @defaults[undasherize(opt)]
          sample ||= case type
            when :optional then undasherize(opt).gsub(/\-/, "_").upcase
            when :numeric  then "N"
            end
          "[" + opt + "=" + sample.to_s + "]"
        end
      end.join(" ")
    end
    
    alias :to_s :formatted_usage

    private
    
    def assert_value!(switch)
      raise Error, "no value provided for argument '#{switch}'" if peek.nil?
    end
    
    def undasherize(str)
      str.sub(/^-{1,2}/, '')
    end
    
    def dasherize(str)
      (str.length > 1 ? "--" : "-") + str
    end
    
    def peek
      @args.first
    end

    def shift
      @args.shift
    end

    def unshift(arg)
      unless arg.kind_of?(Array)
        @args.unshift(arg)
      else
        @args = arg + @args
      end
    end
    
    def valid?(arg)
      @switches.key?(arg) or @shorts.key?(arg)
    end

    def current_is_option?
      case peek
      when LONG_RE, SHORT_RE, EQ_RE, SHORT_NUM
        valid?($1)
      when SHORT_SQ_RE
        $1.split('').any? { |f| valid?("-#{f}") }
      end
    end
    
    def normalize_switch(switch)
      @shorts.key?(switch) ? @shorts[switch] : switch
    end
    
    def switch_type(switch)
      @switches[switch]
    end
    
    def check_required!(hash)
      for name, type in @switches
        if type == :required and !hash[undasherize(name)]
          raise Error, "no value provided for required argument '#{name}'"
        end
      end
    end
    
  end
end
