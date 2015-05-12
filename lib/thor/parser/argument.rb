class Thor
  class Argument #:nodoc:
    VALID_TYPES = [:numeric, :hash, :array, :string]

    attr_reader :name, :description, :enum, :required, :type, :default, :banner, :validator, :validator_description
    alias_method :human_name, :name

    def initialize(name, options = {})
      class_name = self.class.name.split("::").last

      type = options[:type]

      fail ArgumentError, "#{class_name} name can't be nil."                         if name.nil?
      fail ArgumentError, "Type :#{type} is not valid for #{class_name.downcase}s."  if type && !valid_type?(type)

      @name                  = name.to_s
      @description           = options[:desc]
      @required              = options.key?(:required) ? options[:required] : true
      @type                  = (type || :string).to_sym
      @default               = options[:default]
      @banner                = options[:banner] || default_banner
      @enum                  = options[:enum]
      @validator             = options[:validator]
      @validator_description = options[:validator_desc]

      validate! # Trigger specific validations
    end

    def usage
      required? ? banner : "[#{banner}]"
    end

    def required?
      required
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

    def validate!
      if required? && !default.nil?
        fail ArgumentError, "An argument cannot be required and have default value."
      elsif @enum && !@enum.is_a?(Array)
        fail ArgumentError, "An argument cannot have an enum other than an array."
      end

      validate_validator!
    end

    def validate_validator!
      fail ArgumentError, "A validator needs to respond to #call" if validator_with_invalid_api?
      fail ArgumentError, "A validator needs a description. Please define :validator_desc" if validator_without_description?
      fail ArgumentError, "It does not make sense to use both :validator and :enum. Please use either :validator or :enum" if use_enum_and_validator_together?
    end

    def use_enum_and_validator_together?
      validator && enum
    end

    def validator_with_invalid_api?
      validator && !validator.respond_to?(:call)
    end

    def validator_without_description?
      validator && !validator_description
    end

    def valid_type?(type)
      self.class::VALID_TYPES.include?(type.to_sym)
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
