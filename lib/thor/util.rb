class Thor
  module Tasks; end

  # This module holds several utilities methods for converting thor namespaces
  # to constants. For example:
  #
  #   Thor::Utils.constant_to_namespace(Foo::Bar::Baz) #=> "foo:bar:baz"
  #   Thor::Utils.namespace_to_constant("foo:bar:baz") #=> Foo::Bar::Baz
  #
  module Util

    # Tries to get a constant in the given object. We cannot use Object.const_get
    # because it looks for constants in the  ancestor chain, but we only want
    # constants that are defined in the given object.
    #
    # ==== Parameters
    # object<Object>:: The object in which we look for the constant.
    # constant<Object>:: The name of the constant to look for.
    #
    # ==== Returns
    # <Object>:: The constant, if found.
    #
    # ==== Errors
    # NameError:: Raised if the constant can't be found.
    #
    def self.full_const_get(object, constant)
      list = constant.to_s.split("::")
      list.shift if list.first.empty?

      list.each do |x| 
        object = if object.const_defined?(x)
          object.const_get(x)
        else
          object.const_missing(x)
        end
      end

      object
    end

    # Receives a string and search for it in the given bases. If it's found,
    # returns a constant.
    #
    # ==== Parameters
    # string<String>:: The string to be found in the given bases.
    # base<Array>:: Where to look for the string. By default is Thor::Tasks and Object.
    #
    # ==== Returns
    # <Object>:: The first constant found with name "string" in one of the bases.
    #
    # ==== Errors
    # NameError:: Raised if no constant is found.
    #
    def self.make_constant(string, base=[Thor::Tasks, Object])
      base.each do |namespace|
        constant = full_const_get(namespace, string) rescue nil
        return constant if constant
      end
      raise NameError, "uninitialized constant #{string}"
    end

    # Receives a thor namespace and converts it to the constant name. This
    # method returns a string, use namespace_to_constant if you want a constant
    # as result.
    #
    # ==== Parameters
    # namespace<String>
    #
    # ==== Returns
    # constant_name<String>
    # 
    def self.namespace_to_constant_name(namespace)
      namespace = 'default' if namespace.empty?
      namespace.gsub(/:(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
    end

    # Receives a thor namespace and converts it to a constant.
    #
    # ==== Parameters
    # namespace<String>
    #
    # ==== Returns
    # constant<Object>
    #
    # ==== Errors
    # Thor::Error:: Raised if the namespace could not be found.
    #
    def self.namespace_to_constant(namespace)
      make_constant(namespace_to_constant_name(namespace))
    rescue NameError => e
      if e.message =~ /^uninitialized constant (.*)$/
        raise Error, "There was no available namespace '#{namespace}'."
      else
        raise e 
      end
    end

    # Receives a constant and converts it to a Thor namespace. Since Thor tasks
    # can be added to a sandbox, this method is also responsable for removing
    # the sandbox namespace.
    #
    # ==== Parameters
    # constant<Object>:: The constant to be converted to the thor path.
    #
    # ==== Returns
    # String:: If we receive Foo::Bar::Baz it returns "foo:bar:baz"
    #
    def self.constant_to_namespace(constant, remove_default=true)
      constant = constant.to_s.gsub(/^Thor::Tasks::/, "")
      constant = snake_case(constant).squeeze(":")
      constant.gsub!(/^default/, '') if remove_default
      constant
    end

    # Given the contents, evaluate it inside the sandbox and returns the thor
    # classes defined in the sandbox.
    #
    # ==== Parameters
    # contents<String>
    #
    # ==== Returns
    # Array[Object]
    #
    def self.constants_in_contents(contents, file=__FILE__)
      old_constants = Thor.subclasses.dup
      Thor.subclasses.clear

      Thor::Tasks.class_eval(contents, file)

      new_constants = Thor.subclasses.dup
      Thor.subclasses.replace(old_constants)

      new_constants.map do |constant|
        constant.name.gsub(/^Thor::Tasks::/, '')
      end
    end

    # Receives a string and convert it to snake case. SnakeCase returns snake_case.
    #
    # ==== Parameters
    # String
    #
    # ==== Returns
    # String
    #
    def self.snake_case(str)
      return str.downcase if str =~ /^[A-Z_]+$/
      str.gsub(/\B[A-Z]/, '_\&').squeeze('_') =~ /_*(.*)/
      return $+.downcase
    end
  end
end
