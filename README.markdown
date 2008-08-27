thor
====

Map options to a class. Simply create a class with the appropriate annotations, and have options automatically map
to functions and parameters.

Example:

    class MyApp < Thor                                                # [1]
      map "-L" => :list                                               # [2]
                                                                    
      desc "install APP_NAME", "install one of the available apps"    # [3]
      method_options :force => :boolean, :alias => :optional          # [4]
      def install(name)
        user_alias = options[:alias]
        if options.force?
          # do something
        end
        # ... other code ...
      end
      
      desc "list [SEARCH]", "list all of the available apps, limited by SEARCH"
      def list(search = "")
        # list everything
      end
    end
    
Thor automatically maps commands as such:

    app install myname --force
    
That gets converted to:

    MyApp.new.install("myname")
    # with {'force' => true} as options hash

1.  Inherit from Thor to turn a class into an option mapper
2.  Map additional non-valid identifiers to specific methods. In this case,
    convert -L to :list
3.  Describe the method immediately below. The first parameter is the usage information,
    and the second parameter is the description.
4.  Provide any additional options. These will be marshaled from `--` and `-` params.
    In this case, a `--force` and a `-f` option is added.
    
Types for `method_options`
--------------------------

<dl>
  <dt><code>:boolean</code></dt>
    <dd>true if the option is passed</dd>
  <dt><code>true</code></dt>
    <dd>same as <code>:boolean</code></dd>
  <dt><code>:required</code></dt>
    <dd>the value for this option MUST be provided</dd>
  <dt><code>:optional</code></dt>
    <dd>the value for this option MAY be provided</dd>
  <dt><code>:numeric</code></dt>
    <dd>the value MAY be provided, but MUST be in numeric form</dd>
  <dt>a String or Numeric</dt>
    <dd>same as <code>:optional</code>, but fall back to the given object as default value</dd>
</dl>

In case of unsatisfied requirements, `Thor::Options::Error` is raised.

Examples of option parsing:

    # let's say this is how we defined options for a method:
    method_options(:force => :boolean, :retries => :numeric)
    
    # here is how the following command-line invocations would be parsed:
    
    command -f --retries 5    # => {'force' => true, 'retries' => 5}
    command --force -r=5      # => {'force' => true, 'retries' => 5}
    command -fr 5             # => {'force' => true, 'retries' => 5}
    command --retries=5       # => {'retries' => 5}
    command -r5               # => {'retries' => 5}