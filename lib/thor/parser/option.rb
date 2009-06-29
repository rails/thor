class Thor
  class Option
    attr_reader :name, :description, :required, :type, :default, :aliases, :group, :banner

    VALID_TYPES = [:boolean, :numeric, :hash, :array, :string, :default]

    def initialize(name, description=nil, required=nil, type=nil, default=nil, banner=nil, group=nil, aliases=nil)
      raise ArgumentError, "Option name can't be nil."                          if name.nil?
      raise ArgumentError, "Option cannot be required and have default values." if required && !default.nil?
      raise ArgumentError, "Type :#{type} is not valid for options."            if type && !VALID_TYPES.include?(type.to_sym)

      @name        = name.to_s
      @description = description
      @required    = required || false
      @type        = (type || :default).to_sym
      @default     = default
      @aliases     = [*aliases].compact
      @banner      = banner || default_banner
      @group       = group.to_s.capitalize if group
    end

    # This parse quick options given as method_options. It makes several
    # assumptions, but you can be more specific using the option method.
    #
    #   parse :foo => "bar"
    #   #=> Option foo with default value bar
    #
    #   parse [:foo, :baz] => "bar"
    #   #=> Option foo with default value bar and alias :baz
    #
    #   parse :foo => :required
    #   #=> Required option foo without default value
    #
    #   parse :foo => :optional
    #   #=> Optional foo without default value
    #
    #   parse :foo => 2
    #   #=> Option foo with default value 2 and type numeric
    #
    #   parse :foo => :numeric
    #   #=> Option foo without default value and type numeric
    #
    #   parse :foo => true
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

      self.new(name.to_s, nil, required, type, default, nil, nil, aliases)
    end

    def argument?
      false
    end

    def required?
      required
    end

    def input_required?
      [ :numeric, :hash, :array, :string ].include?(type)
    end

    def switch_name
      @switch_name ||= dasherized? ? name : dasherize(name)
    end

    def human_name
      @human_name ||= dasherized? ? undasherize(name) : name
    end

    def usage
      sample = if banner
        "#{switch_name}=#{banner}"
      else
        switch_name
      end

      sample = "[#{sample}]"                      unless required?
      sample = "#{aliases.join(', ')}, #{sample}" unless aliases.empty?
      sample
    end

    def show_default?
      case default
        when Array, String, Hash
          !default.empty?
        else
          default
      end
    end

    protected

      def dasherized?
        name.index('-') == 0
      end

      def undasherize(str)
        str.sub(/^-{1,2}/, '')
      end

      def dasherize(str)
        (str.length > 1 ? "--" : "-") + str.gsub('_', '-')
      end

      def default_banner
        case type
          when :boolean
            nil
          when :string, :default
            human_name.upcase
          when :numeric
            "N"
          when :hash
            "key:value"
          when :array
            "one two three"
        end
      end
  end
end
