require 'thor/core_ext/hash_with_indifferent_access'

class Thor
  class Option < Struct.new(:name, :description, :required, :type, :default, :aliases)
    VALID_TYPES = [:boolean, :numeric, :hash, :array, :string]

    # This parse quick options given as method_options. It makes several
    # assumptions you can be more specific using the option method.
    #
    #   method_options :foo => "bar"
    #   #=> Option foo with default value bar
    #
    #   method_options [:foo, :baz] => "bar"
    #   #=> Option foo with default value bar and alias :baz
    #
    #   method_options :foo => :required
    #   #=> Required option foo without default value
    #
    #   method_options :foo => :optional
    #   #=> Optional foo without default value
    #
    #   method_options :foo => 2
    #   #=> Option foo with default value 2 and type numeric
    #
    #   method_options :foo => :numeric
    #   #=> Option foo without default value and type numeric
    #
    #   method_options :foo => true
    #   #=> Option foo with default value true and type boolean
    #
    # The valid types are :boolean, :numeric, :hash, :array and :string. If none
    # is given a default type is assumed. This default type accepts arguments as
    # string (--foo=value) or booleans (just --foo).
    #
    # By default all options are optional, unless :required is given.
    # 
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

          if VALID_TYPES.include?(value)
            value
          elsif required = (value == :required)
            :string
          end
        when TrueClass, FalseClass
          :boolean
        when Numeric
          :numeric
        when Hash, Array, String
          value.class.name.downcase.to_sym
      end

      required ||= false
      type     ||= :default

      self.new(name.to_s, nil, required, type, default, aliases)
    end

    def required?
      required
    end

    def optional?
      !required
    end

    # Returns true if this type requires an argument to be given. Just :default
    # and :boolean does not require an argument.
    #
    def argument_required?
      [ :numeric, :hash, :array, :string ].include?(type)
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

        mem[arg_name] = option
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

      @leading_non_opts = []
      if skip_leading_non_opts
        @leading_non_opts << shift until current_is_switch? || @args.empty?
      end

      while current_is_switch?
        case shift
          when SHORT_SQ_RE
            unshift($1.split('').map { |f| "-#{f}" })
            next
          when EQ_RE, SHORT_NUM
            unshift($2)
            switch = $1
          when LONG_RE, SHORT_RE
            switch = $1
        end

        switch     = normalize_switch(switch)
        human_name = undasherize(switch)
        option     = switch_option(switch)

        next unless option

        if option.argument_required?
          raise Error, "no value provided for argument '#{switch}'"  if peek.nil?
          raise Error, "cannot pass switch '#{peek}' as an argument" if switch?(peek)
        end

        case option.type
          when :default
            hash[human_name] = peek.nil? || peek.to_s =~ /^-/ || shift
          when :string
            hash[human_name] = shift
          when :boolean
            if !@switches.key?(switch) && human_name =~ /^no-(\w+)$/
              hash[$1] = false
            else
              hash[human_name] = true
            end
          when :numeric
            unless peek =~ NUMERIC and $& == peek
              raise Error, "expected numeric value for '#{switch}'; got #{peek.inspect}"
            end
            hash[human_name] = $&.index('.') ? shift.to_f : shift.to_i
          when :hash
            hash[human_name] = parse_hash(shift)
          # TODO when :array
        end
      end

      @trailing_non_opts = @args

      check_required!(hash)
      hash.freeze
      hash
    end
    
    def formatted_usage
      return "" if @switches.empty?

      # TODO Use switch description when available
      @switches.map do |key, option|
        sample = case option.type
          when :boolean
            nil
          when :string, :default
            option.default || key.gsub(/\-/, "").upcase
          when :numeric
            option.default || "N"
          when :hash
            # TODO Spec me
            if option.default
              option.default.inject([]) do |mem, (key, value)|
                mem << "#{key}:#{value.gsub(/\s/, '_')}"
                mem
              end.join(' ')
            else
              "first_key:first_value second_key:second_value"
            end
          when :array
            # TODO Spec me
            if option.default
              option.default.inspect
            else
              "[1,2,3]"
            end
        end

        sample = if sample
          "#{key}=#{sample}"
        else
          key
        end

        if option.required?
          sample
        else
          "[#{sample}]"
        end
      end.join(" ")
    end
    alias :to_s :formatted_usage

    private

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

      # Returns true if the current peek is a switch.
      #
      def current_is_switch?
        case peek
          when LONG_RE, SHORT_RE, EQ_RE, SHORT_NUM
            switch?($1)
          when SHORT_SQ_RE
            $1.split('').any? { |f| switch?("-#{f}") }
        end
      end

      # Check if the given argument matches with a switch.
      #
      def switch?(arg)
        switch_option(arg) || @shorts.key?(arg)
      end

      # Returns the option object for the given switch.
      #
      def switch_option(arg)
        if arg =~ /^--no-(\w+)$/
          @switches[arg] || @switches["--#{$1}"]
        else
          @switches[arg]
        end
      end

      # Check if the given argument is actually a shortcut.
      #
      def normalize_switch(arg)
        @shorts.key?(arg) ? @shorts[arg] : arg
      end

      # Receives a string in the following format:
      #
      #   name:string age:integer
      #
      # And returns it as a hash:
      #
      #   { "name" => "string", "age" => "integer" }
      #
      def parse_hash(arg)
        arg.split(/\s/).inject({}) do |hash, key_value|
          key, value = key_value.split(':')
          hash[key] = value
          hash
        end
      end

      # Receives a hash and check if all required switches were set.
      #
      def check_required!(hash)
        @switches.each do |name, option|
          if option.required? && hash[undasherize(name)].nil?
            raise Error, "no value provided for required argument '#{name}'"
          end
        end
      end

  end
end
