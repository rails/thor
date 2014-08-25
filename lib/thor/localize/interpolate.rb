# Taken from I18n
class Thor
  module Localize
    module Internal
      @interpolation_pattern = Regexp.union(
        /%%/,
        /%\{(\w+)\}/,                               # matches placeholders like "%{foo}"
        /%<(\w+)>(.*?\d*\.?\d*[bBdiouxXeEfgGcps])/  # matches placeholders like "%<foo>.d"
      )

      class << self
        private

        attr_reader :interpolation_pattern

        public

        # Return String or raises MissingInterpolationArgument exception.
        # Missing argument's logic is handled by I18n.config.missing_interpolation_argument_handler.
        def interpolate(string, values)
          return string if values.nil? || values.empty?

          fail ArgumentError, 'Interpolation values must be a Hash.' unless values.kind_of?(Hash)

          interpolate_hash(string, values)
        end

        private

        def interpolate_hash(string, values)
          string.gsub(interpolation_pattern) do |match|
            if match == '%%'
              '%'
            else
              key = ($1 || $2).to_sym
              value = if values.key?(key)
                        values[key]
                      else
                        message = values.map { |k, v| "key #{k} => value #{v}" }.join(", ")
                        raise InterpolationError, message
                      end
              value = value.call(values) if value.respond_to?(:call)
              $3 ? sprintf("%#{$3}", value) : value
            end
          end
        end
      end
    end
  end
end
