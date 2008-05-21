# This is a modified version of Daniel Berger's Getopt::ong class,
# licensed under Ruby's license.

require 'set'

class Thor
  class Options
    class Error < StandardError; end

    LONG_RE     = /^(--\w+[-\w+]*)?$/
    SHORT_RE    = /^(-\w)$/
    LONG_EQ_RE  = /^(--\w+[-\w+]*)?=(.*?)$|(-\w?)=(.*?)$/
    SHORT_SQ_RE = /^(-\w)(\S+?)$/

    attr_accessor :args

    def initialize(args)
      @args = args
    end

    def skip_non_opts
      non_opts = []
      non_opts << pop until looking_at_opt? || @args.empty?
      non_opts
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
    # opts = Thor::Options.new(args).getopts(
    #    ["--debug"],
    #    ["--verbose", "-v"],
    #    ["--level", "-l", :numeric]
    # )
    #
    # See the README file for more information.
    #
    def getopts(*switches)
      hash  = {} # Hash returned to user
      valid = Set.new # Tracks valid switches
      types = {} # Tracks argument types
      syns  = {} # Tracks long and short arguments, or multiple shorts

      switches = normalize_switches switches

      valid = switches.flatten.reject {|s| s.is_a?(Symbol)}.to_set
      types = switches.inject({}) do |h, (f1,f2,v)|
        h[f1] ||= v
        h[f2] ||= v
        h
      end
      syns  = switches.inject({}) do |h, (f1,f2,_)|
        h[f1] ||= [f1, f2]
        h[f2] ||= [f1, f2]
        h
      end

      while looking_at_opt?
        opt = pop

        # Allow either -x -v or -xv style for single char args
        if SHORT_SQ_RE.match(opt)
          push(opt.split("")[1..-1].map {|s| s = "-#{s}"})
          next
        end

        if match = LONG_RE.match(opt) || match = SHORT_RE.match(opt)
          switch = match.captures.first
        end

        if match = LONG_EQ_RE.match(opt)
          switch, value = match.captures.compact
          push(switch, value)
          next
        end

        # Make sure that all the switches are valid.  If 'switch' isn't
        # defined at this point, it means an option was passed without
        # a preceding switch, e.g. --option foo bar.
        unless valid.include?(switch)
          switch ||= opt
          raise Error, "invalid switch '#{switch}'"
        end

        # Required arguments
        if types[switch] == :required
          nextval = peek

          # Make sure there's a value for mandatory arguments
          if nextval.nil?
            err = "no value provided for required argument '#{switch}'"
            raise Error, err
          end

          # If there is a value, make sure it's not another switch
          if valid.include?(nextval)
            err = "cannot pass switch '#{nextval}' as an argument"
            raise Error, err
          end

          # If the same option appears more than once, put the values
          # in array.
          if hash[switch]
            hash[switch] = [hash[switch], nextval].flatten
          else
            hash[switch] = nextval
          end
          pop
        end

        # For boolean arguments set the switch's value to true.
        if types[switch] == :boolean
          if hash.has_key?(switch)
            raise Error, "boolean switch already set"
          end
          hash[switch] = true
        end

        # For increment arguments, set the switch's value to 0, or
        # increment it by one if it already exists.
        if types[switch] == :increment
          if hash.has_key?(switch)
            hash[switch] += 1
          else
            hash[switch] = 1
          end
        end

        # For optional argument, there may be an argument.  If so, it
        # cannot be another switch.  If not, it is set to true.
        if types[switch] == :optional
          nextval = peek
          if valid.include?(nextval)
            hash[switch] = true
          else
            hash[switch] = nextval
            pop
          end
        end
      end

      normalize_hash syns, hash
    end

    private

    def peek
      @args.first
    end

    def pop
      arg = peek
      @args = @args[1..-1]
      arg
    end

    def push(*args)
      @args = args + @args
    end

    def looking_at_opt?
      (arg = peek) && [LONG_RE, SHORT_RE, LONG_EQ_RE, SHORT_SQ_RE].any? {|re| arg =~ re}
    end

    def normalize_switches(switches)
      # If a string is passed, split it and convert it to an array of arrays
      if switches.first.kind_of?(String)
        switches = switches.join.split.map(&method(:Array))
      end

      switches.map do |switch|
        # Set type for long switch, default to :boolean.
        if switch[1].kind_of?(Symbol)
          [switch[0], switch[0][1..2], switch[1]]
        else
          [switch[0], switch[1] || switch[0][1..2], switch[2] || :boolean]
        end
      end
    end

    def normalize_hash(syns, hash)
      # Set synonymous switches to the same value, e.g. if -t is a synonym
      # for --test, and the user passes "--test", then set "-t" to the same
      # value that "--test" was set to.
      #
      # This allows users to refer to the long or short switch and get
      # the same value
      hash.map do |switch, val|
        syns[switch].map {|key| [key, val]}
      end.inject([]) {|a, v| a + v}.map do |key, value|
        [key.sub(/^-+/, ''), value]
      end.inject({}) {|h, (k,v)| h[k] = v; h}
    end

  end
end
