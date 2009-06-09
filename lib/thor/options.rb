require 'thor/option'
require 'thor/core_ext/hash_with_indifferent_access'

class Thor

  # This is a modified version of Daniel Berger's Getopt::Long class,
  # licensed under Ruby's license.
  #
  class Options
    NUMERIC     = /(\d*\.\d+|\d+)/
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
            value.map {|v| "--#{key} #{v.inspect}"}.join(" ")
          when nil, false
            ""
          else
            "--#{key} #{value.inspect}"
        end
      end.join(" ")
    end

    attr_reader :arguments, :options, :trailing

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
      @defaults, @shorts, @arguments, @options = {}, {}, {}, {}
      @non_assigned_required, @non_assigned_arguments, @trailing = [], [], []

      @switches = switches.values.inject({}) do |mem, option|
        @non_assigned_required  << option if option.required?

        if option.argument?
          @non_assigned_arguments << option
        elsif !option.default.nil?
          @defaults[option.human_name] = option.default
        end

        # If there are no shortcuts specified, generate one using the first character
        shorts = option.aliases.dup
        shorts << "-" + option.human_name[0,1] if shorts.empty? and option.human_name.length > 1
        shorts.each { |short| @shorts[short.to_s] ||= option.switch_name }

        mem[option.switch_name] = option
        mem
      end

      assign_arguments_default_values!
      remove_duplicated_shortcuts!
    end

    def parse(args)
      @pile, @trailing = args, []

      # Start hash with indifferent access pre-filled with defaults
      @options = Thor::CoreExt::HashWithIndifferentAccess.new(@defaults)

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
          option = switch_option(switch)

          next unless option

          check_requirement!(switch, option)

          if option.argument?
            parse_argument(switch, option)
          else
            parse_option(switch, option, @options)
          end
        else
          unless @non_assigned_arguments.empty?
            option = @non_assigned_arguments.shift
            parse_option(option.switch_name, option, @arguments)
          else
            @trailing << shift
          end
        end
      end

      check_validity!
      @options.freeze
      @options
    end

    private

      def peek
        @pile.first
      end

      def shift
        @pile.shift
      end

      def unshift(arg)
        unless arg.kind_of?(Array)
          @pile.unshift(arg)
        else
          @pile = arg + @pile
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

      # Parse the argument. If the argument was already assigned, get the current
      # value, parse the new one and put the old one back on the pile.
      #
      def parse_argument(switch, option)
        unless @non_assigned_arguments.include?(option)
          @trailing << @arguments[option.human_name]
          parse_option(switch, option, @arguments)
        else
          @non_assigned_arguments.delete(option)
          parse_option(switch, option, @arguments)
        end
      end

      # Receives switch, option and the current values hash and assign the next
      # value to it. At the end, remove the option from the array where non
      # assigned requireds are kept.
      #
      def parse_option(switch, option, hash)
        human_name = option.human_name

        case option.type
          when :default
            hash[human_name] = peek.nil? || peek.to_s =~ /^-/ || shift
          when :boolean
            if !@switches.key?(switch) && switch =~ /^--no-(\w+)$/
              hash[$1] = false
            else
              hash[human_name] = true
            end
          when :string
            hash[human_name] = shift
          when :numeric
            hash[human_name] = parse_numeric(switch)
          when :hash
            hash[human_name] = parse_hash
          when :array
            hash[human_name] = parse_array
        end

        @non_assigned_required.delete(option)
      end

      # Runs through the argument array getting strings that contains ":" and
      # mark it as a hash:
      #
      #   [ "name:string", "age:integer" ]
      #
      # Becomes:
      #
      #   { "name" => "string", "age" => "integer" }
      #
      def parse_hash
        hash = {}

        while peek && peek !~ /^\-/
          key, value = shift.split(':')
          hash[key] = value
        end

        hash
      end

      # Runs through the argument array getting all strings until no string is
      # found or a switch is found.
      #
      #   ["a", "b", "c"]
      #
      # And returns it as an array:
      #
      #   ["a", "b", "c"]
      #
      def parse_array
        array = []

        while peek && peek !~ /^\-/
          array << shift
        end

        array
      end

      # Check if the peel is numeric ofrmat and return a Float or Integer.
      # Otherwise raises an error.
      #
      def parse_numeric(switch)
        unless peek =~ NUMERIC && $& == peek
          raise MalformattedArgumentError, "expected numeric value for '#{switch}'; got #{peek.inspect}"
        end
        $&.index('.') ? shift.to_f : shift.to_i
      end

      # Raises an error if the option requires an input but it's not present.
      #
      def check_requirement!(switch, option)
        if option.input_required?
          raise RequiredArgumentMissingError, "no value provided for argument '#{switch}'"  if peek.nil?
          raise MalformattedArgumentError, "cannot pass switch '#{peek}' as an argument" if switch?(peek)
        end
      end

      # Raises an error if @required array is not empty after parsing.
      #
      def check_validity!
        unless @non_assigned_required.empty?
          switch_names = @non_assigned_required.map{ |o| o.switch_name }.join(', ')
          raise RequiredArgumentMissingError, "no value provided for required arguments '#{switch_names}'" 
        end
      end

      # Assign default values to the argument hash.
      #
      def assign_arguments_default_values!
        @non_assigned_arguments.each do |option|
          @arguments[option.human_name] = option.default
        end
      end

      # Remove shortcuts that happen to coincide with any of the main switches
      #
      def remove_duplicated_shortcuts!
        @shorts.keys.each do |short|
          @shorts.delete(short) if @switches.key?(short)
        end
      end

  end
end
