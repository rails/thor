require 'thor/error'
require 'thor/util'

class Thor
  class Task < Struct.new(:meth, :description, :usage, :options, :klass)

    def self.dynamic(meth, klass)
      new(meth, "A dynamically-generated task", meth.to_s, nil, klass)
    end

    def parse(obj, args)
      list, hash = parse_args(args)
      obj.options = hash
      run(obj, *list)
    end

    def run(obj, *params)
      raise NoMethodError, "the `#{meth}' task of #{obj.class} is private" unless public_method?(obj, meth)

      obj.invoke(meth, *params)
    rescue ArgumentError => e
      backtrace = sans_backtrace(e.backtrace, caller)

      # If backtrace is empty, they called Thor wrongly. Otherwise re-raise the
      # original error.
      #
      if backtrace.empty?
        raise Error, "`#{meth}' was called incorrectly. Call as `#{formatted_usage}'"
      else
        raise e
      end
    rescue NoMethodError => e
      if e.message =~ /^undefined method `#{meth}' for #{Regexp.escape(obj.inspect)}$/
        raise Error, "The #{namespace(false)} namespace doesn't have a `#{meth}' task"
      else
        raise e
      end
    end

    def namespace(remove_default=true)
      Thor::Util.constant_to_thor_path(klass, remove_default)
    end

    def with_klass(klass)
      new = self.dup
      new.klass = klass
      new
    end

    # Merge the options given on task creation with the klass options and
    # returns as a Options object.
    #
    def opts
      @opts ||= Options.new((klass.opts || {}).merge(options || {}))
    end

    def formatted_usage(namespace = false)
      formatted = ''
      formatted << "#{self.namespace}:" if namespace
      formatted << usage
      formatted << " #{opts.formatted_usage}"
      formatted.strip!
      formatted
    end

    protected

      def parse_args(args)
        return [[], {}] if args.nil?
        hash = opts.parse(args)
        list = opts.non_opts
        [list, hash]
      end

      def public_method?(obj, meth)
        !(obj.private_methods + obj.protected_methods).include?(meth)
      end

      # Clean everything that comes from the Thor gempath and remove the caller.
      #
      def sans_backtrace(backtrace, caller)
        dirname = /^#{Regexp.escape(File.dirname(__FILE__))}/
        saned  = backtrace.reject { |frame| frame =~ dirname }
        saned -= caller
      end

  end
end
