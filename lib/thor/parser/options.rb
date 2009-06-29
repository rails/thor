class Thor

  # This is a modified version of Daniel Berger's Getopt::Long class, licensed
  # under Ruby's license.
  #
  class Options < Parser
    attr_reader :arguments, :options
  
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
      @arguments, @shorts, @options = [], {}, {}
      @non_assigned_required = []

      @switches = switches.values.inject({}) do |mem, option|
        @non_assigned_required  << option if option.required?

        option.aliases.each do |short|
          @shorts[short.to_s] ||= option.switch_name
        end

        mem[option.switch_name] = option
        mem
      end
    end

    def parse(args)
      @pile = args.dup

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
            raise RequiredArgumentMissingError, "no value provided for required argument '#{switch}'" if peek.nil?
            raise MalformattedArgumentError, "cannot pass switch '#{peek}' as an argument" unless current_is_value?
          end

          @options[option.human_name] = parse_option(switch, option)
        else
          shift
        end
      end

      check_requirement!
      @options
    end

    def parse_arguments(arguments, args)
      @pile = args.dup
      assigns = {}

      # TODO Check validity!
      arguments.each do |argument|
        assigns[argument.human_name] = if peek
          send(:"parse_#{argument.type}", argument.switch_name)
        else
          argument.default
        end
      end

      assigns
    end

  end
end
