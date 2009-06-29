class Thor

  # This is a modified version of Daniel Berger's Getopt::Long class, licensed
  # under Ruby's license.
  #
  class Parser
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

    # Receives an array of args and returns two arrays, one with arguments
    # and one with switches.
    #
    def self.split(args)
      arguments = []

      args.each do |item|
        break if item =~ /^-/
        arguments << item
      end

      return arguments, args[Range.new(arguments.size, -1)]
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

      def current_is_switch?
        case peek
          when LONG_RE, SHORT_RE, EQ_RE, SHORT_NUM
            switch?($1)
          when SHORT_SQ_RE
            $1.split('').any? { |f| switch?("-#{f}") }
        end
      end

      def current_is_value?
        peek && peek.to_s !~ /^-/
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

      # Receives switch, option and the current values hash and assign the next
      # value to it. At the end, remove the option from the array where non
      # assigned requireds are kept.
      #
      def parse_option(switch, option)
        @non_assigned_required.delete(option)

        type = if option.type == :default
          current_is_value? ? :string : :boolean
        else
          option.type
        end

        send(:"parse_#{type}", switch)
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
      def parse_hash(switch)
        return shift if peek.is_a?(Hash)
        hash = {}

        while current_is_value? && peek.include?(?:)
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
      def parse_array(switch)
        return shift if peek.is_a?(Array)
        array = []

        while current_is_value?
          array << shift
        end
        array
      end

      # Check if the peel is numeric ofrmat and return a Float or Integer.
      # Otherwise raises an error.
      #
      def parse_numeric(switch)
        return shift if peek.is_a?(Numeric)

        unless peek =~ NUMERIC && $& == peek
          raise MalformattedArgumentError, "expected numeric value for '#{switch}'; got #{peek.inspect}"
        end

        $&.index('.') ? shift.to_f : shift.to_i
      end

      # Parse string, i.e., just return the current value in the pile.
      #
      def parse_string(switch)
        shift
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

      # Raises an error if @required array is not empty after parsing.
      #
      def check_requirement!
        unless @non_assigned_required.empty?
          names = @non_assigned_required.map do |o|
            o.argument? ? o.human_name : o.switch_name
          end.join("', '")

          raise RequiredArgumentMissingError, "no value provided for required arguments '#{names}'"
        end
      end

  end
end
require 'thor/parser/options'
require 'thor/parser/arguments'
