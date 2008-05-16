class Thor
  class Util
    
    def self.constant_to_thor_path(str)
      snake_case(str).squeeze(":").gsub(/^default/, '')
    end

    def self.constant_from_thor_path(str)
      make_constant(to_constant(str))
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

    private  

    def self.make_constant(str)
      list = str.split("::")
      obj = Object
      list.each {|x| obj = obj.const_get(x) }
      obj
    end
    
    def self.snake_case(str)
      return str.downcase if str =~ /^[A-Z]+$/
      str.gsub(/([A-Z]+)(?=[A-Z][a-z]?)|\B[A-Z]/, '_\&') =~ /_*(.*)/
      return $+.downcase
    end  
    
  end
end
