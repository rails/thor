require 'thor/parser/option'

class Thor
  # Argument is a subset of option. It does not support :boolean and :default
  # as types.
  #
  class Argument < Option
    VALID_TYPES = [:numeric, :hash, :array, :string]

    def initialize(name, description=nil, required=true, type=:string, default=nil, banner=nil)
      raise ArgumentError, "Argument name can't be nil."               if name.nil?
      raise ArgumentError, "Type :#{type} is not valid for arguments." if type && !VALID_TYPES.include?(type.to_sym)

      super(name, description, required, type || :string, default, banner)
    end

    def argument?
      true
    end

    def usage
      required? ? banner : "[#{banner}]"
    end
  end
end
