require 'thor/error'
require 'thor/util'

class Thor
  class Task < Struct.new(:description, :usage, :options)

    def namespace(klass, remove_default=true)
      Thor::Util.constant_to_thor_path(klass, remove_default)
    end

    def opts(klass=nil)
      klass_opts = if klass && klass.respond_to?(:opts)
        klass.opts
      else
        {}
      end

      Options.new(klass_opts.merge(options || {}))
    end

    def formatted_usage(klass=nil, use_namespace=true)
      formatted = ''
      formatted << "#{namespace(klass)}:" if klass && use_namespace
      formatted << usage
      formatted << " #{opts(klass).formatted_usage}"
      formatted.strip!
      formatted
    end

  end
end
