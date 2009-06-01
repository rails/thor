class Thor
  module Sandbox; end

  # This module holds several utilities:
  #
  # 1) Methods to convert thor namespaces to constants and vice-versa.
  #
  #   Thor::Utils.constant_to_namespace(Foo::Bar::Baz) #=> "foo:bar:baz"
  #   Thor::Utils.namespace_to_constant("foo:bar:baz") #=> Foo::Bar::Baz
  #
  # 2) Loading thor files and sandboxing:
  #
  #   Thor::Utils.load_thorfile("~/.thor/foo")
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
    # base<Array>:: Where to look for the string. By default is Thor::Sandbox and Object.
    #
    # ==== Returns
    # <Object>:: The first constant found with name "string" in one of the bases.
    #
    # ==== Errors
    # NameError:: Raised if no constant is found.
    #
    def self.make_constant(string, base=[Thor::Sandbox, Object])
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
      constant = constant.to_s.gsub(/^Thor::Sandbox::/, "")
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
      old_constants = Thor::Base.subclasses.dup
      Thor::Base.subclasses.clear

      load_thorfile(file, contents)

      new_constants = Thor::Base.subclasses.dup
      Thor::Base.subclasses.replace(old_constants)

      new_constants.map do |constant|
        constant.name.gsub(/^Thor::Sandbox::/, '')
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

    # Receives a namespace and tries to retrieve a Thor or Thor::Generator class
    # from it. If a Thor class is found, also returns the task.
    #
    # ==== Examples
    #
    #   class Foo::Bar < Thor
    #     def baz
    #     end
    #   end
    #
    #   class Baz::Foo < Thor::Generator
    #   end
    #
    #   Thor::Util.namespace_to_thor_class("baz:foo")     #=> Baz::Foo, nil
    #   Thor::Util.namespace_to_thor_class("foo:bar:baz") #=> Foo::Bar, "baz"
    #
    # ==== Parameters
    # namespace<String>
    #
    # ==== Errors
    # Thor::Error:: raised if the namespace cannot be found.
    #
    # Thor::Error:: raised if the namespace evals to a class which does not
    #               inherit from Thor or Thor::Generator.
    #
    def self.namespace_to_thor_class(namespace)
      generator = Thor::Util.namespace_to_constant(namespace) rescue nil

      if generator
        raise Error, "'#{generator}' is not a Thor::Generator class" unless generator <= Thor::Generator
        return generator, nil
      elsif !namespace.include?(?:)
        raise Error, "could not find generator or task '#{namespace}'"
      end

      namespace = namespace.split(":")
      task_name = namespace.pop
      klass     = Thor::Util.namespace_to_constant(namespace.join(":"))

      raise Error, "'#{klass}' is not a Thor class" unless klass <= Thor

      return klass, task_name
    end

    # Receives a path and load the thor file in the path. The file is evaluated
    # inside the sandbox to avoid namespacing conflicts.
    #
    def self.load_thorfile(path, content=nil)
      content ||= File.read(path)

      begin
        Thor::Sandbox.class_eval(content, path)
      rescue Exception => e
        $stderr.puts "WARNING: unable to load thorfile #{path.inspect}: #{e.message}"
      end
    end

    # Prints a list. Used to show options and list of tasks.
    #
    # TODO Spec'it
    #
    def self.print_list(list)
      return if list.empty?

      maxima = list.max{ |a,b| a[0].size <=> b[0].size }[0].size
      format = "  %-#{maxima+3}s"

      list.each do |name, description|
        print format % name
        print "# #{description}" if description
        puts
      end
    end
  end
end
