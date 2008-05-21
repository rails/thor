# This is a modified version of Daniel Berger's Getopt::ong class,
# licensed under Ruby's license.

require 'set'

class Thor
  class Options
    class Error < StandardError; end

    LONG_RE     = /^(--\w+[-\w+]*)?$/
    SHORT_RE    = /^(-\w)$/
    LONG_EQ_RE  = /^(--\w+[-\w+]*)?=(.*?)$|(-\w?)=(.*?)$/
    SHORT_SQ_RE = /^-(\w\S+?)$/ # Allow either -x -v or -xv style for single char args

    attr_accessor :args

    def initialize(args, switches)
      @args = args

      switches = switches.map do |names, type|
        type = :boolean if type == true
        names = [names, names[2].chr] if names.is_a?(String)
        [names, type]
      end

      @valid = switches.map {|s| s.first}.flatten.to_set
      @types = switches.inject({}) do |h, (forms,v)|
        forms.each {|f| h[f] ||= v}
        h
      end
      @syns = switches.inject({}) do |h, (forms,_)|
        forms.each {|f| h[f] ||= forms}
        h
      end
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
    # opts = Thor::Options.new(args,
    #    "--debug" => true,
    #    ["--verbose", "-v"] => true,
    #    ["--level", "-l"] => :numeric
    # ).getopts
    #
    def getopts
      hash  = {}

      while looking_at_opt?
        case pop
        when SHORT_SQ_RE
          push($1.split("").map {|s| s = "-#{s}"})
          next
        when LONG_EQ_RE
          push($1, $2)
          next
        when LONG_RE, SHORT_RE
          switch = $1
        end

        raise Error, "in@valid switch '#{switch}'" unless @valid.include?(switch)

        # Required arguments
        if @types[switch] == :required
          nextval = peek

          raise Error, "no value provided for required argument '#{switch}'" if nextval.nil?
          raise Error, "cannot pass switch '#{nextval}' as an argument" if @valid.include?(nextval)

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
        if @types[switch] == :boolean
          raise Error, "boolean switch already set" if hash.has_key?(switch)
          hash[switch] = true
        end

        # For increment arguments, set the switch's value to one, or
        # increment it by one if it already exists.
        if @types[switch] == :increment
          hash[switch] ||= 0
          hash[switch] += 1
        end

        # For optional argument, there may be an argument.  If so, it
        # cannot be another switch.  If not, it is set to true.
        if @types[switch] == :optional
          nextval = peek
          hash[switch] = @valid.include?(peek) || pop
        end
      end

      normalize_hash hash
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
      case peek
      when LONG_RE, SHORT_RE, LONG_EQ_RE
        @valid.include? $1
      when SHORT_SQ_RE
        $1.split("").any? {|f| @valid.include? "-#{f}"}
      end
    end

    def normalize_hash(hash)
      # Set synonymous switches to the same value, e.g. if -t is a synonym
      # for --test, and the user passes "--test", then set "-t" to the same
      # value that "--test" was set to.
      #
      # This allows users to refer to the long or short switch and get
      # the same value
      hash.map do |switch, val|
        @syns[switch].map {|key| [key, val]}
      end.inject([]) {|a, v| a + v}.map do |key, value|
        [key.sub(/^-+/, ''), value]
      end.inject({}) {|h, (k,v)| h[k] = v; h}
    end

  end
end
