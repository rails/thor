require "helper"

describe Thor do
  describe "#method_option" do
    it "sets options to the next method to be invoked" do
      args = %w(foo bar --force)
      _, options = MyScript.start(args)
      expect(options).to eq("force" => true)
    end

    describe ":lazy_default" do
      it "is absent when option is not specified" do
        _, options = MyScript.start(%w(with_optional))
        expect(options).to eq({})
      end

      it "sets a default that can be overridden for strings" do
        _, options = MyScript.start(%w(with_optional --lazy))
        expect(options).to eq("lazy" => "yes")

        _, options = MyScript.start(%w(with_optional --lazy yesyes!))
        expect(options).to eq("lazy" => "yesyes!")
      end

      it "sets a default that can be overridden for numerics" do
        _, options = MyScript.start(%w(with_optional --lazy-numeric))
        expect(options).to eq("lazy_numeric" => 42)

        _, options = MyScript.start(%w(with_optional --lazy-numeric 20000))
        expect(options).to eq("lazy_numeric" => 20_000)
      end

      it "sets a default that can be overridden for arrays" do
        _, options = MyScript.start(%w(with_optional --lazy-array))
        expect(options).to eq("lazy_array" => %w(eat at joes))

        _, options = MyScript.start(%w(with_optional --lazy-array hello there))
        expect(options).to eq("lazy_array" => %w(hello there))
      end

      it "sets a default that can be overridden for hashes" do
        _, options = MyScript.start(%w(with_optional --lazy-hash))
        expect(options).to eq("lazy_hash" => {"swedish" => "meatballs"})

        _, options = MyScript.start(%w(with_optional --lazy-hash polish:sausage))
        expect(options).to eq("lazy_hash" => {"polish" => "sausage"})
      end
    end

    describe "when :for is supplied" do
      it "updates an already defined command" do
        _, options = MyChildScript.start(%w(animal horse --other=fish))
        expect(options[:other]).to eq("fish")
      end

      describe "and the target is on the parent class" do
        it "updates an already defined command" do
          args = %w(example_default_command my_param --new-option=verified)
          options = Scripts::MyScript.start(args)
          expect(options[:new_option]).to eq("verified")
        end

        it "adds a command to the command list if the updated command is on the parent class" do
          expect(Scripts::MyScript.commands["example_default_command"]).to be
        end

        it "clones the parent command" do
          expect(Scripts::MyScript.commands["example_default_command"]).not_to eq(MyChildScript.commands["example_default_command"])
        end
      end
    end
  end

  describe "#default_command" do
    it "sets a default command" do
      expect(MyScript.default_command).to eq("example_default_command")
    end

    it "invokes the default command if no command is specified" do
      expect(MyScript.start([])).to eq("default command")
    end

    it "invokes the default command if no command is specified even if switches are given" do
      expect(MyScript.start(%w(--with option))).to eq("with" => "option")
    end

    it "inherits the default command from parent" do
      expect(MyChildScript.default_command).to eq("example_default_command")
    end
  end

  describe "#stop_on_unknown_option!" do
    my_script = Class.new(Thor) do
      class_option "verbose",   :type => :boolean
      class_option "mode",      :type => :string

      stop_on_unknown_option! :exec

      desc "exec", "Run a command"
      def exec(*args)
        [options, args]
      end

      desc "boring", "An ordinary command"
      def boring(*args)
        [options, args]
      end
    end

    it "passes remaining args to command when it encounters a non-option" do
      expect(my_script.start(%w(exec command --verbose))).to eq [{}, %w(command --verbose)]
    end

    it "passes remaining args to command when it encounters an unknown option" do
      expect(my_script.start(%w(exec --foo command --bar))).to eq [{}, %w(--foo command --bar)]
    end

    it "still accepts options that are given before non-options" do
      expect(my_script.start(%w(exec --verbose command --foo))).to eq [{"verbose" => true}, %w(command --foo)]
    end

    it "still accepts options that require a value" do
      expect(my_script.start(%w(exec --mode rashly command))).to eq [{"mode" => "rashly"}, %w(command)]
    end

    it "still passes everything after -- to command" do
      expect(my_script.start(%w(exec -- --verbose))).to eq [{}, %w(--verbose)]
    end

    it "still passes everything after -- to command, complex" do
      expect(my_script.start(%w[exec command --mode z again -- --verbose more])).to eq [{}, %w[command --mode z again -- --verbose more]]
    end

    it "does not affect ordinary commands" do
      expect(my_script.start(%w(boring command --verbose))).to eq [{"verbose" => true}, %w(command)]
    end

    context "when provided with multiple command names" do
      klass = Class.new(Thor) do
        stop_on_unknown_option! :foo, :bar
      end
      it "affects all specified commands" do
        expect(klass.stop_on_unknown_option?(double(:name => "foo"))).to be true
        expect(klass.stop_on_unknown_option?(double(:name => "bar"))).to be true
        expect(klass.stop_on_unknown_option?(double(:name => "baz"))).to be false
      end
    end

    context "when invoked several times" do
      klass = Class.new(Thor) do
        stop_on_unknown_option! :foo
        stop_on_unknown_option! :bar
      end
      it "affects all specified commands" do
        expect(klass.stop_on_unknown_option?(double(:name => "foo"))).to be true
        expect(klass.stop_on_unknown_option?(double(:name => "bar"))).to be true
        expect(klass.stop_on_unknown_option?(double(:name => "baz"))).to be false
      end
    end

    it "doesn't break new" do
      expect(my_script.new).to be_a(Thor)
    end

    context "along with check_unknown_options!" do
      my_script2 = Class.new(Thor) do
        class_option "verbose",   :type => :boolean
        class_option "mode",      :type => :string
        check_unknown_options!
        stop_on_unknown_option! :exec

        desc "exec", "Run a command"
        def exec(*args)
          [options, args]
        end

        def self.exit_on_failure?
          false
        end
      end

      it "passes remaining args to command when it encounters a non-option" do
        expect(my_script2.start(%w[exec command --verbose])).to eq [{}, %w[command --verbose]]
      end

      it "does not accept if first non-option looks like an option, but only refuses that invalid option" do
        expect(capture(:stderr) do
          my_script2.start(%w[exec --foo command --bar])
        end.strip).to eq("Unknown switches \"--foo\"")
      end

      it "still accepts options that are given before non-options" do
        expect(my_script2.start(%w[exec --verbose command])).to eq [{"verbose" => true}, %w[command]]
      end

      it "still accepts when non-options are given after real options and argument" do
        expect(my_script2.start(%w[exec --verbose command --foo])).to eq [{"verbose" => true}, %w[command --foo]]
      end

      it "does not accept when non-option looks like an option and is after real options" do
        expect(capture(:stderr) do
          my_script2.start(%w[exec --verbose --foo])
        end.strip).to eq("Unknown switches \"--foo\"")
      end

      it "still accepts options that require a value" do
        expect(my_script2.start(%w[exec --mode rashly command])).to eq [{"mode" => "rashly"}, %w[command]]
      end

      it "still passes everything after -- to command" do
        expect(my_script2.start(%w[exec -- --verbose])).to eq [{}, %w[--verbose]]
      end

      it "still passes everything after -- to command, complex" do
        expect(my_script2.start(%w[exec command --mode z again -- --verbose more])).to eq [{}, %w[command --mode z again -- --verbose more]]
      end
    end
  end

  describe "#check_unknown_options!" do
    my_script = Class.new(Thor) do
      class_option "verbose",   :type => :boolean
      class_option "mode",      :type => :string
      check_unknown_options!

      desc "checked", "a command with checked"
      def checked(*args)
        [options, args]
      end

      def self.exit_on_failure?
        false
      end
    end

    it "still accept options and arguments" do
      expect(my_script.start(%w[checked command --verbose])).to eq [{"verbose" => true}, %w[command]]
    end

    it "still accepts options that are given before arguments" do
      expect(my_script.start(%w[checked --verbose command])).to eq [{"verbose" => true}, %w[command]]
    end

    it "does not accept if non-option that looks like an option is before the arguments" do
      expect(capture(:stderr) do
        my_script.start(%w[checked --foo command --bar])
      end.strip).to eq("Unknown switches \"--foo\", \"--bar\"")
    end

    it "does not accept if non-option that looks like an option is after an argument" do
      expect(capture(:stderr) do
        my_script.start(%w[checked command --foo --bar])
      end.strip).to eq("Unknown switches \"--foo\", \"--bar\"")
    end

    it "does not accept when non-option that looks like an option is after real options" do
      expect(capture(:stderr) do
        my_script.start(%w[checked --verbose --foo])
      end.strip).to eq("Unknown switches \"--foo\"")
    end

    it "does not accept when non-option that looks like an option is before real options" do
      expect(capture(:stderr) do
        my_script.start(%w[checked --foo --verbose])
      end.strip).to eq("Unknown switches \"--foo\"")
    end

    it "still accepts options that require a value" do
      expect(my_script.start(%w[checked --mode rashly command])).to eq [{"mode" => "rashly"}, %w[command]]
    end

    it "still passes everything after -- to command" do
      expect(my_script.start(%w[checked -- --verbose])).to eq [{}, %w[--verbose]]
    end

    it "still passes everything after -- to command, complex" do
      expect(my_script.start(%w[checked command --mode z again -- --verbose more])).to eq [{"mode" => "z"}, %w[command again --verbose more]]
    end
  end

  describe "#disable_required_check!" do
    my_script = Class.new(Thor) do
      class_option "foo", :required => true

      disable_required_check! :boring

      desc "exec", "Run a command"
      def exec(*args)
        [options, args]
      end

      desc "boring", "An ordinary command"
      def boring(*args)
        [options, args]
      end

      def self.exit_on_failure?
        false
      end
    end

    it "does not check the required option in the given command" do
      expect(my_script.start(%w(boring command))).to eq [{}, %w(command)]
    end

    it "does check the required option of the remaining command" do
      content = capture(:stderr) { my_script.start(%w(exec command)) }
      expect(content).to eq "No value provided for required options '--foo'\n"
    end

    it "does affects help by default" do
      expect(my_script.disable_required_check?(double(:name => "help"))).to be true
    end

    context "when provided with multiple command names" do
      klass = Class.new(Thor) do
        disable_required_check! :foo, :bar
      end

      it "affects all specified commands" do
        expect(klass.disable_required_check?(double(:name => "help"))).to be true
        expect(klass.disable_required_check?(double(:name => "foo"))).to be true
        expect(klass.disable_required_check?(double(:name => "bar"))).to be true
        expect(klass.disable_required_check?(double(:name => "baz"))).to be false
      end
    end

    context "when invoked several times" do
      klass = Class.new(Thor) do
        disable_required_check! :foo
        disable_required_check! :bar
      end

      it "affects all specified commands" do
        expect(klass.disable_required_check?(double(:name => "help"))).to be true
        expect(klass.disable_required_check?(double(:name => "foo"))).to be true
        expect(klass.disable_required_check?(double(:name => "bar"))).to be true
        expect(klass.disable_required_check?(double(:name => "baz"))).to be false
      end
    end
  end

  describe "#map" do
    it "calls the alias of a method if one is provided" do
      expect(MyScript.start(%w(-T fish))).to eq(%w(fish))
    end

    it "calls the alias of a method if several are provided via #map" do
      expect(MyScript.start(%w(-f fish))).to eq(["fish", {}])
      expect(MyScript.start(%w(--foo fish))).to eq(["fish", {}])
    end

    it "inherits all mappings from parent" do
      expect(MyChildScript.default_command).to eq("example_default_command")
    end
  end

  describe "#package_name" do
    it "provides a proper description for a command when the package_name is assigned" do
      content = capture(:stdout) { PackageNameScript.start(%w(help)) }
      expect(content).to match(/Baboon commands:/m)
    end

    # TODO: remove this, might be redundant, just wanted to prove full coverage
    it "provides a proper description for a command when the package_name is NOT assigned" do
      content = capture(:stdout) { MyScript.start(%w(help)) }
      expect(content).to match(/Commands:/m)
    end
  end

  describe "#desc" do
    it "provides description for a command" do
      content = capture(:stdout) { MyScript.start(%w(help)) }
      expect(content).to match(/thor my_script:zoo\s+# zoo around/m)
    end

    it "provides no namespace if $thor_runner is false" do
      begin
        $thor_runner = false
        content = capture(:stdout) { MyScript.start(%w(help)) }
        expect(content).to match(/thor zoo\s+# zoo around/m)
      ensure
        $thor_runner = true
      end
    end

    describe "when :for is supplied" do
      it "overwrites a previous defined command" do
        expect(capture(:stdout) { MyChildScript.start(%w(help)) }).to match(/animal KIND \s+# fish around/m)
      end
    end

    describe "when :hide is supplied" do
      it "does not show the command in help" do
        expect(capture(:stdout) { MyScript.start(%w(help)) }).not_to match(/this is hidden/m)
      end

      it "but the command is still invokable, does not show the command in help" do
        expect(MyScript.start(%w(hidden yesyes))).to eq(%w(yesyes))
      end
    end
  end

  describe "#method_options" do
    it "sets default options if called before an initializer" do
      options = MyChildScript.class_options
      expect(options[:force].type).to eq(:boolean)
      expect(options[:param].type).to eq(:numeric)
    end

    it "overwrites default options if called on the method scope" do
      args = %w(zoo --force --param feathers)
      options = MyChildScript.start(args)
      expect(options).to eq("force" => true, "param" => "feathers")
    end

    it "allows default options to be merged with method options" do
      args = %w(animal bird --force --param 1.0 --other tweets)
      arg, options = MyChildScript.start(args)
      expect(arg).to eq("bird")
      expect(options).to eq("force" => true, "param" => 1.0, "other" => "tweets")
    end
  end

  describe "#start" do
    it "calls a no-param method when no params are passed" do
      expect(MyScript.start(%w(zoo))).to eq(true)
    end

    it "calls a single-param method when a single param is passed" do
      expect(MyScript.start(%w(animal fish))).to eq(%w(fish))
    end

    it "does not set options in attributes" do
      expect(MyScript.start(%w(with_optional --all))).to eq([nil, {"all" => true}, []])
    end

    it "raises an error if the wrong number of params are provided" do
      arity_asserter = lambda do |args, msg|
        stderr = capture(:stderr) { Scripts::Arities.start(args) }
        expect(stderr.strip).to eq(msg)
      end
      arity_asserter.call %w(zero_args one), 'ERROR: "thor zero_args" was called with arguments ["one"]
Usage: "thor scripts:arities:zero_args"'
      arity_asserter.call %w(one_arg), 'ERROR: "thor one_arg" was called with no arguments
Usage: "thor scripts:arities:one_arg ARG"'
      arity_asserter.call %w(one_arg one two), 'ERROR: "thor one_arg" was called with arguments ["one", "two"]
Usage: "thor scripts:arities:one_arg ARG"'
      arity_asserter.call %w(one_arg one two), 'ERROR: "thor one_arg" was called with arguments ["one", "two"]
Usage: "thor scripts:arities:one_arg ARG"'
      arity_asserter.call %w(two_args one), 'ERROR: "thor two_args" was called with arguments ["one"]
Usage: "thor scripts:arities:two_args ARG1 ARG2"'
      arity_asserter.call %w(optional_arg one two), 'ERROR: "thor optional_arg" was called with arguments ["one", "two"]
Usage: "thor scripts:arities:optional_arg [ARG]"'
      arity_asserter.call %w(multiple_usages), 'ERROR: "thor multiple_usages" was called with no arguments
Usage: "thor scripts:arities:multiple_usages ARG --foo"
       "thor scripts:arities:multiple_usages ARG --bar"'
    end

    it "raises an error if the invoked command does not exist" do
      expect(capture(:stderr) { Amazing.start(%w(animal)) }.strip).to eq('Could not find command "animal" in "amazing" namespace.')
    end

    it "calls method_missing if an unknown method is passed in" do
      expect(MyScript.start(%w(unk hello))).to eq([:unk, %w(hello)])
    end

    it "does not call a private method no matter what" do
      expect(capture(:stderr) { MyScript.start(%w(what)) }.strip).to eq('Could not find command "what" in "my_script" namespace.')
    end

    it "uses command default options" do
      options = MyChildScript.start(%w(animal fish)).last
      expect(options).to eq("other" => "method default")
    end

    it "raises when an exception happens within the command call" do
      expect { MyScript.start(%w(call_myself_with_wrong_arity)) }.to raise_error(ArgumentError)
    end

    context "when the user enters an unambiguous substring of a command" do
      it "invokes a command" do
        expect(MyScript.start(%w(z))).to eq(MyScript.start(%w(zoo)))
      end

      it "invokes a command, even when there's an alias it resolves to the same command" do
        expect(MyScript.start(%w(hi arg))).to eq(MyScript.start(%w(hidden arg)))
      end

      it "invokes an alias" do
        expect(MyScript.start(%w(animal_pri))).to eq(MyScript.start(%w(zoo)))
      end
    end

    context "when the user enters an ambiguous substring of a command" do
      it "raises an exception and displays a message that explains the ambiguity" do
        shell = Thor::Base.shell.new
        expect(shell).to receive(:error).with("Ambiguous command call matches [call_myself_with_wrong_arity, call_unexistent_method]")
        MyScript.start(%w(call), :shell => shell)
      end

      it "raises an exception when there is an alias" do
        shell = Thor::Base.shell.new
        expect(shell).to receive(:error).with("Ambiguous command f matches [foo, fu]")
        MyScript.start(%w(f), :shell => shell)
      end
    end
  end

  describe "#help" do
    def shell
      @shell ||= Thor::Base.shell.new
    end

    describe "on general" do
      before do
        @content = capture(:stdout) { MyScript.help(shell) }
      end

      it "provides useful help info for the help method itself" do
        expect(@content).to match(/help \[COMMAND\]\s+# Describe available commands/)
      end

      it "provides useful help info for a method with params" do
        expect(@content).to match(/animal TYPE\s+# horse around/)
      end

      it "uses the maximum terminal size to show commands" do
        expect(@shell).to receive(:terminal_width).and_return(80)
        content = capture(:stdout) { MyScript.help(shell) }
        expect(content).to match(/aaa\.\.\.$/)
      end

      it "provides description for commands from classes in the same namespace" do
        expect(@content).to match(/baz\s+# do some bazing/)
      end

      it "shows superclass commands" do
        content = capture(:stdout) { MyChildScript.help(shell) }
        expect(content).to match(/foo BAR \s+# do some fooing/)
      end

      it "shows class options information" do
        content = capture(:stdout) { MyChildScript.help(shell) }
        expect(content).to match(/Options\:/)
        expect(content).to match(/\[\-\-param=N\]/)
      end

      it "injects class arguments into default usage" do
        content = capture(:stdout) { Scripts::MyScript.help(shell) }
        expect(content).to match(/zoo ACCESSOR \-\-param\=PARAM/)
      end
    end

    describe "for a specific command" do
      it "provides full help info when talking about a specific command" do
        expect(capture(:stdout) { MyScript.command_help(shell, "foo") }).to eq(<<-END)
Usage:
  thor my_script:foo BAR

Options:
  [--force]  # Force to do some fooing

do some fooing
  This is more info!
  Everyone likes more info!
END
      end

      it "provides full help info when talking about a specific command with multiple usages" do
        expect(capture(:stdout) { MyScript.command_help(shell, "baz") }).to eq(<<-END)
Usage:
  thor my_script:baz THING
  thor my_script:baz --all

Options:
  [--all=ALL]  # Do bazing for all the things

super cool
END
      end

      it "raises an error if the command can't be found" do
        expect do
          MyScript.command_help(shell, "unknown")
        end.to raise_error(Thor::UndefinedCommandError, 'Could not find command "unknown" in "my_script" namespace.')
      end

      it "normalizes names before claiming they don't exist" do
        expect(capture(:stdout) { MyScript.command_help(shell, "name-with-dashes") }).to match(/thor my_script:name-with-dashes/)
      end

      it "uses the long description if it exists" do
        expect(capture(:stdout) { MyScript.command_help(shell, "long_description") }).to eq(<<-HELP)
Usage:
  thor my_script:long_description

Description:
  This is a really really really long description. Here you go. So very long.

  It even has two paragraphs.
HELP
      end

      it "doesn't assign the long description to the next command without one" do
        expect(capture(:stdout) do
          MyScript.command_help(shell, "name_with_dashes")
        end).not_to match(/so very long/i)
      end
    end

    describe "instance method" do
      it "calls the class method" do
        expect(capture(:stdout) { MyScript.start(%w(help)) }).to match(/Commands:/)
      end

      it "calls the class method" do
        expect(capture(:stdout) { MyScript.start(%w(help foo)) }).to match(/Usage:/)
      end
    end

    context "with required class_options" do
      let(:klass) do
        Class.new(Thor) do
          class_option :foo, :required => true

          desc "bar", "do something"
          def bar; end
        end
      end

      it "shows the command help" do
        content = capture(:stdout) { klass.start(%w(help)) }
        expect(content).to match(/Commands:/)
      end
    end
  end

  describe "subcommands" do
    it "triggers a subcommand help when passed --help" do
      parent = Class.new(Thor)
      child  = Class.new(Thor)
      parent.desc "child", "child subcommand"
      parent.subcommand "child", child
      parent.desc "dummy", "dummy"
      expect(child).to receive(:help).with(anything, anything)
      parent.start ["child", "--help"]
    end
  end

  describe "when creating commands" do
    it "prints a warning if a public method is created without description or usage" do
      expect(capture(:stdout) do
        klass = Class.new(Thor)
        klass.class_eval "def hello_from_thor; end"
      end).to match(/\[WARNING\] Attempted to create command "hello_from_thor" without usage or description/)
    end

    it "does not print if overwriting a previous command" do
      expect(capture(:stdout) do
        klass = Class.new(Thor)
        klass.class_eval "def help; end"
      end).to be_empty
    end
  end

  describe "edge-cases" do
    it "can handle boolean options followed by arguments" do
      klass = Class.new(Thor) do
        method_option :loud, :type => :boolean
        desc "hi NAME", "say hi to name"
        def hi(name)
          name = name.upcase if options[:loud]
          "Hi #{name}"
        end
      end

      expect(klass.start(%w(hi jose))).to eq("Hi jose")
      expect(klass.start(%w(hi jose --loud))).to eq("Hi JOSE")
      expect(klass.start(%w(hi --loud jose))).to eq("Hi JOSE")
    end

    it "passes through unknown options" do
      klass = Class.new(Thor) do
        desc "unknown", "passing unknown options"
        def unknown(*args)
          args
        end
      end

      expect(klass.start(%w(unknown foo --bar baz bat --bam))).to eq(%w(foo --bar baz bat --bam))
      expect(klass.start(%w(unknown --bar baz))).to eq(%w(--bar baz))
    end

    it "does not pass through unknown options with strict args" do
      klass = Class.new(Thor) do
        strict_args_position!

        desc "unknown", "passing unknown options"
        def unknown(*args)
          args
        end
      end

      expect(klass.start(%w(unknown --bar baz))).to eq([])
      expect(klass.start(%w(unknown foo --bar baz))).to eq(%w(foo))
    end

    it "strict args works in the inheritance chain" do
      parent = Class.new(Thor) do
        strict_args_position!
      end

      klass = Class.new(parent) do
        desc "unknown", "passing unknown options"
        def unknown(*args)
          args
        end
      end

      expect(klass.start(%w(unknown --bar baz))).to eq([])
      expect(klass.start(%w(unknown foo --bar baz))).to eq(%w(foo))
    end

    it "issues a deprecation warning on incompatible types by default" do
      expect do
        Class.new(Thor) do
          option "bar", :type => :numeric, :default => "foo"
        end
      end.to output(/^Deprecation warning/).to_stderr
    end

    it "allows incompatible types if allow_incompatible_default_type! is called" do
      expect do
        Class.new(Thor) do
          allow_incompatible_default_type!

          option "bar", :type => :numeric, :default => "foo"
        end
      end.not_to output.to_stderr
    end

    it "allows incompatible types if `check_default_type: false` is given" do
      expect do
        Class.new(Thor) do
          option "bar", :type => :numeric, :default => "foo", :check_default_type => false
        end
      end.not_to output.to_stderr
    end

    it "checks the default type when check_default_type! is called" do
      expect do
        Class.new(Thor) do
          check_default_type!

          option "bar", :type => :numeric, :default => "foo"
        end
      end.to raise_error(ArgumentError, "Expected numeric default value for '--bar'; got \"foo\" (string)")
    end

    it "send as a command name" do
      expect(MyScript.start(%w(send))).to eq(true)
    end
  end

  context "without an exit_on_failure? method" do
    my_script = Class.new(Thor) do
      desc "no arg", "do nothing"
      def no_arg
      end
    end

    it "outputs a deprecation warning on error" do
      expect do
        my_script.start(%w[no_arg one])
      end.to output(/^Deprecation.*exit_on_failure/).to_stderr
    end
  end

end
