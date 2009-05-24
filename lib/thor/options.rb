require 'thor/core_ext/hash_with_indifferent_access'

class Thor
  # TODO Remove stub type when refactoring finishes
  class Option < Struct.new(:name, :description, :required, :type, :default, :aliases, :stub_type)
    VALID_TYPES = [:boolean, :numeric, :hash, :array, :string]

    def self.parse(key, value)
      if key.is_a?(Array)
        name, *aliases = key
      else
        name, aliases = key, []
      end

      name    = name.to_s
      default = value

      type = case value
        when Symbol
          default  = nil
          required = (value == :required)
          value if VALID_TYPES.include?(value)
        when TrueClass, FalseClass
          :boolean
        when Numeric
          :numeric
        when Hash
          :hash
        when Array
          :array
      end

      required ||= false
      type     ||= :string

      stub_type = if required
        :required
      elsif type == :string
        :optional
      else
        type
      end

      self.new(name.to_s, nil, required, type, default, aliases, stub_type)
    end
  end

  # This is a modified version of Daniel Berger's Getopt::Long class,
  # licensed under Ruby's license.
  #
  class Options
    class Error < StandardError; end

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
    def initialize(switches={})
      @defaults = {}
      @shorts = {}
      
      @leading_non_opts, @trailing_non_opts = [], []

      @switches = switches.inject({}) do |mem, (name, type)|
        option = Thor::Option.parse(name, type)

        # We need both human and dasherized (--name) form of switch name
        if option.name.index('-') == 0
          arg_name, human_name = option.name, undasherize(option.name)
        else
          arg_name, human_name = dasherize(option.name), option.name
        end

        @defaults[human_name] = option.default unless option.default.nil?

        # If there are no shortcuts specified, generate one using the first character
        shorts = option.aliases.dup
        shorts << "-" + human_name[0,1] if shorts.empty? and human_name.length > 1
        shorts.each { |short| @shorts[short] = arg_name }

        mem[arg_name] = option.stub_type
        mem
      end
      
      # remove shortcuts that happen to coincide with any of the main switches
      @shorts.keys.each do |short|
        @shorts.delete(short) if @switches.key?(short)
      end
    end

    def parse(args, skip_leading_non_opts = true)
      @args = args

      # Start hash with indifferent access pre-filled with defaults
      hash = Thor::CoreExt::HashWithIndifferentAccess.new @defaults

      @leading_non_opts = [ ]
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
          if !@switches.key?(switch) && nice_name =~ /^no-(\w+)$/
            hash[$1] = false
          else
            hash[nice_name] = true
          end
          
        when :numeric
          assert_value!(switch)
          unless peek =~ NUMERIC and $& == peek
            raise Error, "expected numeric value for '#{switch}'; got #{peek.inspect}"
          end
          hash[nice_name] = $&.index('.') ? shift.to_f : shift.to_i
        when :hash
          assert_value!(switch)
          raise Error, "cannot pass switch '#{peek}' as an argument" if valid?(peek)
          hash[nice_name] = parse_hash(shift)
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
      if arg.to_s =~ /^--no-(\w+)$/
        @switches.key?(arg) or (@switches["--#{$1}"] == :boolean)
      else
        @switches.key?(arg) or @shorts.key?(arg)
      end
    end

    def parse_hash(arg)
      hash = {}

      arg.split(/\s/).each do |key_value|
        key, value = key_value.split(':')
        hash[key] = value
      end

      hash
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
      if switch =~ /^--no-(\w+)$/
        @switches[switch] || @switches["--#{$1}"]
      else
        @switches[switch]
      end
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
