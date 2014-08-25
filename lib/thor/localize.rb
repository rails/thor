require 'psych'
require "thor/localize/internal"
require "thor/localize/interpolate"

class Thor
  module Localize
    @backend = Thor::Localize::Internal

    attr_accessor :backend

    def t(translation_key, interpolation_values = {})
      backend.t(translation_key, interpolation_values)
    end

    module_function :backend, :t
  end
end
