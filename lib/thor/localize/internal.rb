class Thor
  module Localize
    module Internal
      class << self
        def t(translation_key, interpolation_values)
          file_path = File.expand_path('../internal.yaml', __FILE__)
          data = Psych.load(File.read(file_path))

          string = translation_key.split(/\./).inject(data) do |a, e|
            fail InvalidLocalizationKeyError, "Translation missing: #{translation_key}" unless a.key?(e)
            fail InvalidLocalizationKeyError, "Translation missing: #{translation_key}" unless a[e].is_a?(String) || a[e].is_a?(Hash)

            a[e]
          end

          interpolate(string, interpolation_values)
        end
      end
    end
  end
end
