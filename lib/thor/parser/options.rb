class Thor
  # This is a modified version of Daniel Berger's Getopt::Long class, licensed
  # under Ruby's license.
  #
  class Options < Arguments
    LONG_RE     = /^(--\w+[-\w+]*)$/
    SHORT_RE    = /^(-[a-z])$/i
    EQ_RE       = /^(--\w+[-\w+]*|-[a-z])=(.*)$/i
    SHORT_SQ_RE = /^-([a-z]{2,})$/i # Allow either -x -v or -xv style for single char args
    SHORT_NUM   = /^(-[a-z])#{NUMERIC}$/i

    # Receives a hash and makes it switches.
    #
    def self.to_switches(options)
      options.map do |key, value|
        case value
          when true
            "--#{key}"
          when Array
            "--#{key} #{value.map{ |v| v.inspect }.join(' ')}"
          when Hash
            "--#{key} #{value.map{ |k,v| "#{k}:#{v}" }.join(' ')}"
          when nil, false
            ""
          else
            "--#{key} #{value.inspect}"
        end
      end.join(" ")
    end

    # Takes a hash of Thor::Option objects.
    #
    def initialize(switches={})
      @shorts, @non_assigned_required = {}, []

      @switches = switches.values.inject({}) do |mem, option|
        @non_assigned_required << option if option.required?

        option.aliases.each do |short|
          @shorts[short.to_s] ||= option.switch_name
        end

        mem[option.switch_name] = option
        mem
      end
    end

    def parse(args)
      @pile, options = args.dup, {}

      while peek
        if current_is_switch?
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

          switch = normalize_switch(switch)
          next unless option = switch_option(switch)

          if option.input_required?
            raise RequiredArgumentMissingError, "no value provided for required option '#{switch}'" if peek.nil?
            raise MalformattedArgumentError, "cannot pass switch '#{peek}' as an argument" unless current_is_value?
          end

          options[option.human_name] = parse_peek(switch, option)
        else
          shift
        end
      end

      check_requirement!
      options
    end

    protected

      # Returns true if the current value in peek is a registered switch.
      #
      def current_is_switch?
        case peek
          when LONG_RE, SHORT_RE, EQ_RE, SHORT_NUM
            switch?($1)
          when SHORT_SQ_RE
            $1.split('').any? { |f| switch?("-#{f}") }
        end
      end

      def switch?(arg)
        switch_option(arg) || @shorts.key?(arg)
      end

      def switch_option(arg)
        if arg =~ /^--(no|skip)-([-\w]+)$/
          @switches[arg] || @switches["--#{$2}"]
        else
          @switches[arg]
        end
      end

      # Check if the given argument is actually a shortcut.
      #
      def normalize_switch(arg)
        @shorts.key?(arg) ? @shorts[arg] : arg
      end

      # Parse boolean values which can be given as --foo=true, --foo or --no-foo.
      #
      def parse_boolean(switch)
        if current_is_value?
          ["true", "TRUE", "t", "T", true].include?(shift)
        else
          @switches.key?(switch) || switch !~ /^--(no|skip)-([-\w]+)$/
        end
      end

      # Receives switch, option and the current values hash and assign the next
      # value to it. Also removes the option from the array where non assigned
      # required are kept.
      #
      def parse_peek(switch, option)
        @non_assigned_required.delete(option)

        type = if option.type == :default
          current_is_value? ? :string : :boolean
        else
          option.type
        end

        send(:"parse_#{type}", switch)
      end

  end
end
