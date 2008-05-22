# This is a modified version of Daniel Berger's Getopt::ong class,
# licensed under Ruby's license.

require 'set'

class Thor
  class Options
    class Error < StandardError; end

    LONG_RE     = /^(--\w+[-\w+]*)$/
    SHORT_RE    = /^(-\w)$/
    LONG_EQ_RE  = /^(--\w+[-\w+]*)=(.*?)$|(-\w?)=(.*?)$/
    SHORT_SQ_RE = /^-(\w\S+?)$/ # Allow either -x -v or -xv style for single char args

    attr_accessor :args

    def initialize(args, switches)
      @args = args

      switches = switches.map do |names, type|
        type = :boolean if type == true

        if names.is_a?(String)
          if names =~ LONG_RE
            names = [names, "-" + names[2].chr]
          else
            names = [names]
          end
        end

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
          push(*$1.split("").map {|s| s = "-#{s}"})
          next
        when LONG_EQ_RE
          push($1, $2)
          next
        when LONG_RE, SHORT_RE
          switch = $1
        end

        case @types[switch]
        when :required
          raise Error, "no value provided for required argument '#{switch}'" if peek.nil?
          raise Error, "cannot pass switch '#{peek}' as an argument" if @valid.include?(peek)
          hash[switch] = pop
        when :boolean
          hash[switch] = true
        when :optional
          # For optional arguments, there may be an argument.  If so, it
          # cannot be another switch.  If not, it is set to true.
          hash[switch] = @valid.include?(peek) || peek.nil? || pop
        end
      end

      check_required_args hash
      normalize_hash hash
    end

    private

    def peek
      @args.first
    end

    def pop
      arg = peek
      @args = @args[1..-1] || []
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

    def check_required_args(hash)
      @types.select {|k,v| v == :required}.map {|k,v| @syns[k]}.uniq.each do |syns|
        raise Error, "no value provided for required argument '#{syns.first}'" unless syns.any? {|s| hash[s]}
      end
    end

    # Set synonymous switches to the same value, e.g. if -t is a synonym
    # for --test, and the user passes "--test", then set "-t" to the same
    # value that "--test" was set to.
    #
    # This allows users to refer to the long or short switch and get
    # the same value
    def normalize_hash(hash)
      hash.map do |switch, val|
        @syns[switch].map {|key| [key, val]}
      end.inject([]) {|a, v| a + v}.map do |key, value|
        [key.sub(/^-+/, ''), value]
      end.inject({}) {|h, (k,v)| h[k] = v; h}
    end

  end
end
