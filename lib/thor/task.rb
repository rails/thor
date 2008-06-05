require 'thor/error'
require 'thor/util'

class Thor
  class Task < Struct.new(:meth, :description, :usage, :opts, :klass)
    def self.dynamic(meth, klass)
      new(meth, "A dynamically-generated task", meth.to_s, nil, klass)
    end

    def parse(obj, args)
      run(obj, *parse_args(args))
    end

    def run(obj, *params)
      raise NoMethodError, "the `#{meth}' task of #{obj.class} is private" if
        (obj.private_methods + obj.protected_methods).include?(meth)

      obj.send(meth, *params)
    rescue ArgumentError => e
      # backtrace sans anything in this file
      backtrace = e.backtrace.reject {|frame| frame =~ /^#{Regexp.escape(__FILE__)}/}
      # and sans anything that got us here
      backtrace -= caller
      raise e unless backtrace.empty?

      # okay, they really did call it wrong
      raise Error, "`#{meth}' was called incorrectly. Call as `#{formatted_usage}'"
    rescue NoMethodError => e
      raise e unless e.message =~ /^undefined method `#{meth}' for #{obj.inspect}$/
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
        if val == true || val == :boolean
          "[#{opt}]"
        elsif val == :required
          opt + "=" + opt.gsub(/\-/, "").upcase
        elsif val == :optional
          "[" + opt + "=" + opt.gsub(/\-/, "").upcase + "]"
        end
      end.join(" ")
    end

    def formatted_usage(namespace = false)
      (namespace ? self.namespace + ':' : '') + usage +
        (opts ? " " + formatted_opts : "")
    end

    protected

    def parse_args(args)
      return args unless opts
      options = Thor::Options.new(args, opts)
      hash = options.getopts(false)
      list = options.skip_non_opts
      hash.merge!(options.getopts(false))
      options.check_required_args hash
      list + [hash]
    end
  end
end
