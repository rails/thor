require 'thor/error'
require 'thor/util'

class Thor
  class Task < Struct.new(:meth, :description, :usage, :opts, :klass)
    
    def self.dynamic(meth, klass)
      new(meth, "A dynamically-generated task", meth.to_s, nil, klass)
    end
    
    def initialize(*args)
      # keep the original opts - we need them later on
      @options = args[3] || {}
      super
    end

    def parse(obj, args)
      list, hash = parse_args(args)
      obj.options = hash
      run(obj, *list)
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
      begin
        raise e unless e.message =~ /^undefined method `#{meth}' for #{Regexp.escape(obj.inspect)}$/
      rescue
        raise e
      end
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
    
    def opts
      return super unless super.kind_of? Hash
      @_opts ||= Options.new(super)
    end
        
    def full_opts
      @_full_opts ||= Options.new((klass.opts || {}).merge(@options))
    end
    
    def formatted_usage(namespace = false)
      (namespace ? self.namespace + ':' : '') + usage +
        (opts ? " " + opts.formatted_usage : "")
    end

    protected

    def parse_args(args)
      return [[], {}] if args.nil?
      hash = full_opts.parse(args)
      list = full_opts.non_opts
      [list, hash]
    end
  end
end
