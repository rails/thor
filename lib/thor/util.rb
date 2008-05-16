require 'thor/error'

class Thor
  module Util
    
    def self.constant_to_thor_path(str, remove_default = true)
      str = snake_case(str.to_s).squeeze(":")
      str.gsub!(/^default/, '') if remove_default
      str
    end

    def self.constant_from_thor_path(str)
      make_constant(to_constant(str))
    rescue NameError => e
      raise e unless e.message =~ /^uninitialized constant (.*)$/
      raise Error, "There was no available namespace `#{str}'."
    end

    def self.to_constant(str)
      str = 'default' if str.empty?
      str.gsub(/:(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
    end

    def self.constants_in_contents(str)
      klasses = self.constants.dup
      eval(str)
      ret = self.constants - klasses
      ret.each {|k| self.send(:remove_const, k)}
      ret
    end

    def self.make_constant(str)
      list = str.split("::").inject(Object) {|obj, x| obj.const_get(x)}
    end
    
    def self.snake_case(str)
      return str.downcase if str =~ /^[A-Z_]+$/
      str.gsub(/\B[A-Z]/, '_\&').squeeze('_') =~ /_*(.*)/
      return $+.downcase
    end  
    
  end
end
