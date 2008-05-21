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
    # opts = Thor::Options.getopts(args,
    #    ["--debug"],
    #    ["--verbose", "-v"],
    #    ["--level", "-l", :numeric]
    # )
    #
    # See the README file for more information.
    #
    def self.getopts(args, *switches)
      if switches.empty?
        raise ArgumentError, "no switches provided"
      end

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
        h[f1] ||= f2
        h[f2] ||= f1
        h
      end

      args.each_with_index do |opt, index|

        # Allow either -x -v or -xv style for single char args
        if SHORT_SQ_RE.match(opt)
          chars = opt.split("")[1..-1].map {|s| s = "-#{s}"}

          chars.each_with_index do |char, i|
            unless valid.include?(char)  
              raise Error, "invalid switch '#{char}'"
            end

            # Grab the next arg if the switch takes a required arg
            if types[char] == :required
              # Deal with a argument squished up against switch
              if chars[i+1]
                arg = chars[i+1..-1].join.tr("-","")
                args.push(char, arg)
                break
              else
                arg = args.delete_at(index+1)
                if arg.nil? || valid.include?(arg) # Minor cheat here
                  err = "no value provided for required argument '#{char}'"
                  raise Error, err
                end
                args.push(char, arg)
              end
            elsif types[char] == :optional
              if chars[i+1] && !valid.include?(chars[i+1])
                arg = chars[i+1..-1].join.tr("-","")
                args.push(char, arg)
                break
              elsif
                if args[index+1] && !valid.include?(args[index+1])
                  arg = args.delete_at(index+1)
                  args.push(char, arg)
                end
              else
                args.push(char)
              end
            else
              args.push(char)
            end
          end
          next
        end

        if match = LONG_RE.match(opt) || match = SHORT_RE.match(opt)
          switch = match.captures.first
        end

        if match = LONG_EQ_RE.match(opt)
          switch, value = match.captures.compact
          args.push(switch, value)
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
          nextval = args[index+1]

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
          args.delete_at(index+1)
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
          nextval = args[index+1]
          if valid.include?(nextval)
            hash[switch] = true
          else
            hash[switch] = nextval
            args.delete_at(index+1)
          end
        end
      end

      # Set synonymous switches to the same value, e.g. if -t is a synonym
      # for --test, and the user passes "--test", then set "-t" to the same
      # value that "--test" was set to.
      #
      # This allows users to refer to the long or short switch and get
      # the same value
      hash.each do |switch, val|
        if syns.keys.include?(switch)
          syns[switch].each do |key|
            hash[key] = val   
          end
        end
      end

      # Get rid of leading "--" and "-" to make it easier to reference
      hash.each do |key, value|
        if key[0,2] == '--'
          nkey = key.sub('--', '')
        else
          nkey = key.sub('-', '')
        end
        hash.delete(key)
        hash[nkey] = value
      end

      hash
    end

    def self.normalize_switches(switches)
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

  end
end
