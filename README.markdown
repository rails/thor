thor
====

Map options to a class. Simply create a class with the appropriate annotations, and have options automatically map
to functions and parameters.

Examples:

    class MyApp
      extend Hermes                                                           # [1]
      
      map "-L" => :list                                                       # [2]
      
      desc "install APP_NAME", "install one of the available apps"            # [3]
      method_options :force => :boolean                                       # [4]
      def install(name, opts)
        ... code ...
        if opts[:force]
          # do something
        end
      end
      
      desc "list [SEARCH]", "list all of the available apps, limited by SEARCH"
      def list(search = "")
        # list everything
      end
      
    end
    
    MyApp.start
    
Hermes automatically maps commands as follows:

    app install name --force
    
That gets converted to:

    MyApp.new.install("name", :force => true)
  
[1] Use `extend Hermes` to turn a class into an option mapper

[2] Map additional non-valid identifiers to specific methods. In this case,
    convert -L to :list
    
[3] Describe the method immediately below. The first parameter is the usage information,
    and the second parameter is the description.
    
[4] Provide any additional options. These will be marshaled from -- and - params.
    In this case, a --force and a -f option is added.
    
Types for `method_options`
--------------------------

<dl>
  <dt>:boolean</dt>
  <dd>true if the option is passed</dd>
  <dt>:required</dt>
  <dd>A key/value option that MUST be provided</dd>
  <dt>:optional</dt>
  <dd>A key/value option that MAY be provided</dd>
</dl>