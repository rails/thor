require 'thor/error'
require 'thor/util'

class Thor
  class Task < Struct.new(:meth, :description, :usage, :opts, :klass)
    def self.dynamic(meth, klass)
      new(meth, "A dynamically-generated task", meth.to_s, nil, klass)
    end

    def run(*params)
      raise Error, "klass is not defined for #{self.inspect}" unless klass
      raise NoMethodError, "the `#{meth}' task of #{klass} is private" if
        (klass.private_instance_methods + klass.protected_instance_methods).include?(meth)
      klass.new.send(meth, *params)
    rescue ArgumentError => e
      raise e unless e.backtrace.first =~ /:in `#{meth}'$/
      raise Error, "`#{meth}' was called incorrectly. Call as `#{formatted_usage}'"
    rescue NoMethodError => e
      raise e unless e.message =~ /^undefined method `#{meth}' for #<#{klass}:.*>$/
      raise Error, "The #{namespace false} namespace doesn't have a `#{meth}' task"
    end

    def namespace(remove_default = true)
      Thor::Util.constant_to_thor_path(klass, remove_default)
    end

    def with_klass(klass)
      new = self.dup
      new.klass = klass
      new
    end

    def formatted_opts
      return "" if opts.nil?
      opts.map do |opt, val|
        if val == true || val == "BOOLEAN"
          "[#{opt}]"
        elsif val == "REQUIRED"
          opt + "=" + opt.gsub(/\-/, "").upcase
        elsif val == "OPTIONAL"
          "[" + opt + "=" + opt.gsub(/\-/, "").upcase + "]"
        end
      end.join(" ")
    end

    def formatted_usage(namespace = false)
      (namespace ? self.namespace + ':' : '') + usage +
        (opts ? " " + formatted_opts : "")
    end
  end
end
