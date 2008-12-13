require 'thor/error'

module ObjectSpace
  
  class << self

    # @return <Array[Class]> All the classes in the object space.
    def classes
      klasses = []
      ObjectSpace.each_object(Class) {|o| klasses << o}
      klasses
    end
  end
  
end

class Thor
  module Tasks; end
  
  module Util
    
    def self.full_const_get(obj, name)
      list = name.split("::")
      list.shift if list.first.empty?
      list.each do |x| 
        # This is required because const_get tries to look for constants in the 
        # ancestor chain, but we only want constants that are HERE
        obj = obj.const_defined?(x) ? obj.const_get(x) : obj.const_missing(x)
      end
      obj
    end
    
    def self.constant_to_thor_path(str, remove_default = true)
      str = str.to_s.gsub(/^Thor::Tasks::/, "")
      str = snake_case(str).squeeze(":")
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

    def self.constants_in_contents(str, file = __FILE__)
      klasses = ObjectSpace.classes.dup
      Module.new.class_eval(str, file)
      klasses = ObjectSpace.classes - klasses
      klasses = klasses.select {|k| k < Thor }
      klasses.map! {|k| k.to_s.gsub(/#<Module:\w+>::/, '')}
    end

    def self.make_constant(str, base = [Thor::Tasks, Object])
      which = base.find do |obj|
        full_const_get(obj, str) rescue nil
      end
      return full_const_get(which, str) if which
      raise NameError, "uninitialized constant #{str}"
    end
    
    def self.snake_case(str)
      return str.downcase if str =~ /^[A-Z_]+$/
      str.gsub(/\B[A-Z]/, '_\&').squeeze('_') =~ /_*(.*)/
      return $+.downcase
    end  
    
  end
end
