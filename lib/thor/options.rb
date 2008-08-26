# This is a modified version of Daniel Berger's Getopt::Long class,
# licensed under Ruby's license.

class Thor
  class Options
    class Error < StandardError; end
    
    # read-only Hash with indifferent access
    class Hash < ::Hash
      def initialize(hash)
        super()
        update hash
        freeze
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
    end

    LONG_RE     = /^--(\w+[-\w+]*)$/
    SHORT_RE    = /^-(\w)$/
    EQ_RE       = /^(?:--(\w+[-\w+]*)|-(\w))=(.*)$/
    SHORT_SQ_RE = /^-(\w{2,})$/ # Allow either -x -v or -xv style for single char args
    
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

      @switches = switches.inject({}) do |mem, (name, type)|
        if name.is_a?(Array)
          name, *shorts = name
          shorts = shorts.map { |short| undash_leading short }
        else
          shorts = []
        end
        name = undash_leading name
        # if there are no shortcuts specified, generate one using the first character
        shorts << name[0,1] if shorts.empty? and name.length > 1
        shorts.each { |short| @shorts[short] = name }
        
        # normalize type
        case type
        when TrueClass then type = :boolean
        when String
          @defaults[name] = type
          type = :optional
        end
        
        mem[name] = type
        mem
      end
      
      # remove shortcuts that happen to coincide with one of the main switches
      @shorts.keys.each do |short|
        @shorts.delete(short) if @switches.key?(short)
      end
    end

    def parse(args, skip_leading_non_opts = true)
      @args = args
      hash = @defaults.dup
      
      @leading_non_opts = []
      if skip_leading_non_opts
        @leading_non_opts << shift until current_is_option? || @args.empty?
      end

      while current_is_option?
        case shift
        when SHORT_SQ_RE
          unshift $1.split('').map { |f| "-#{f}" }
          next
        when EQ_RE
          unshift $3
          switch = $1 || $2
        when LONG_RE, SHORT_RE
          switch = $1
        end
        
        switch = normalize_switch(switch)
        
        case switch_type(switch)
        when :required
          raise Error, "no value provided for argument '#{switch}'" if peek.nil?
          raise Error, "cannot pass switch '#{peek}' as an argument" if valid?(peek, true)
          hash[switch] = shift
        when :optional
          hash[switch] = peek.nil? || valid?(peek, true) || shift
        when :boolean
          hash[switch] = true
        end
      end
      
      @trailing_non_opts = @args

      check_required! hash
      # convert to Thor::Options::Hash before returning
      Hash.new(hash)
    end

    private
    
    def undash_leading(str)
      str.sub(/^-{1,2}/, '')
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
    
    def valid?(arg, raw = false)
      raise ArgumentError, "string expected, #{arg.inspect} given" unless arg
      if raw
        return false unless LONG_RE =~ arg || SHORT_RE =~ arg
        arg = $1
      end
      @switches.key?(arg) or @shorts.key?(arg)
    end

    def current_is_option?
      case peek
      when LONG_RE, SHORT_RE, EQ_RE
        valid?($1 || $2)
      when SHORT_SQ_RE
        $1.split('').any? { |f| valid?(f) }
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
        if type == :required and !hash[name]
          raise Error, "no value provided for required argument '#{name}'"
        end
      end
    end
    
  end
end
