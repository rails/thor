require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Thor::Actions do
  def runner(config={})
    @runner ||= MyCounter.new([], {}, { :root => destination_root }.merge(config))
  end

  def file
    File.join(destination_root, "foo")
  end

  describe "on include" do
    it "adds runtime options to the base class" do
      MyCounter.class_options.keys.must include(:pretend)
      MyCounter.class_options.keys.must include(:force)
      MyCounter.class_options.keys.must include(:quiet)
      MyCounter.class_options.keys.must include(:skip)
    end
  end

  describe "#initialize" do
    it "has default behavior invoke" do
      runner.behavior.must == :invoke
    end

    it "can have behavior revoke" do
      runner(:behavior => :revoke).behavior.must == :revoke
    end

    %w(skip force pretend).each do |behavior|
      it "accepts #{behavior.to_sym} as behavior" do
        thor = runner(:behavior => behavior.to_sym)
        thor.behavior.must == :invoke
        thor.options.send(:"#{behavior}?").must be_true
      end

      it "overwrites options values with configuration values" do
        thor = MyCounter.new([], { behavior => false }, :behavior => behavior.to_sym)
        thor.options.send(:"#{behavior}?").must be_true
      end
    end
  end

  describe "accessors" do
    describe "#root=" do
      it "gets the current directory and expands the path to set the root" do
        base = MyCounter.new
        base.root = "here"
        base.root.must == File.expand_path(File.join(File.dirname(__FILE__), "..", "here"))
      end

      it "does not use the current directory if one is given" do
        base = MyCounter.new
        base.root = "/"
        base.root.must == "/"
      end

      it "uses the current directory if none is given" do
        MyCounter.new.root.must == File.expand_path(File.join(File.dirname(__FILE__), ".."))
      end
    end

    describe "#relative_root" do
      it "returns the current root relative to the absolute root" do
        runner.inside "foo" do
          runner.relative_root.must == "foo"
        end
      end
    end

    describe "#relative_to_absolute_root" do
      it "returns the path relative to the absolute root" do
        runner.relative_to_absolute_root(file).must == "foo"
      end

      it "does not remove dot if required" do
        runner.relative_to_absolute_root(file, false).must == "./foo"
      end

      it "always use the absolute root" do
        runner.inside("foo") do
          runner.relative_to_absolute_root(file).must == "foo"
        end
      end
    end

    describe "#source_root" do
      it "raises an error if source root is not specified" do
        runner = Object.new
        runner.extend Thor::Actions

        lambda {
          runner.source_root
        }.must raise_error(NoMethodError, "You have to specify the class method source_root in your thor class.")
      end
    end
  end

  describe "#inside" do
    it "executes the block inside the given folder" do
      runner.inside("foo") do
        Dir.pwd.must == file
      end
    end

    it "changes the base root" do
      capture(:stdout) do
        runner.inside("foo") do
          runner.root.must == file
        end
      end
    end

    it "creates the directory if it does not exist" do
      runner.inside("foo") do
        File.exists?(file).must be_true
      end
    end
  end

  describe "#in_root" do
    it "executes the block in the root folder" do
      runner.inside("foo") do
        runner.in_root { Dir.pwd.must == destination_root }
      end
    end

    it "changes the base root" do
      runner.inside("foo") do
        runner.in_root { runner.root.must == destination_root }
      end
    end

    it "returns to the previous state" do
      runner.inside("foo") do
        runner.in_root { }
        runner.root.must == file
      end
    end
  end

  describe "commands" do
    describe "#chmod" do
      it "executes the command given" do
        mock(FileUtils).chmod_R(0755, file)
        capture(:stdout) { runner.chmod("foo", 0755) }
      end

      it "does not execute the command if pretending given" do
        dont_allow(FileUtils).chmod_R(0755, file)
        capture(:stdout) { runner(:behavior => :pretend).chmod("foo", 0755) }
      end

      it "logs status" do
        mock(FileUtils).chmod_R(0755, file)
        capture(:stdout) { runner.chmod("foo", 0755) }.must == "     [CHMOD] foo\n"
      end

      it "does not log status if required" do
        mock(FileUtils).chmod_R(0755, file)
        capture(:stdout) { runner.chmod("foo", 0755, false) }.must be_empty
      end
    end

    describe "#run" do
      it "executes the command given" do
        mock(runner).`("ls"){ 'spec' } # To avoid highlighting issues `
        capture(:stdout) { runner.run('ls') }
      end

      it "does not execute the command if pretend given" do
        dont_allow(runner(:behavior => :pretend)).`("cd ./") # To avoid highlighting issues `
        capture(:stdout) { runner.run('cd ./') }
      end

      it "logs status" do
        mock(runner).`("ls"){ 'spec' } # To avoid highlighting issues `
        capture(:stdout) { runner.run('ls') }.must == "       [RUN] ls from .\n"
      end

      it "does not log status if required" do
        mock(runner).`("ls"){ 'spec' } # To avoid highlighting issues `
        capture(:stdout) { runner.run('ls', false) }.must be_empty
      end

      it "accepts a color as status" do
        mock(runner).`("ls"){ 'spec' } # To avoid highlighting issues `
        mock(runner.shell).say_status(:run, "ls from .", :yellow)
        runner.run('ls', :yellow)
      end
    end

    describe "#run_ruby_script" do
      it "executes the ruby script" do
        mock(runner).run("ruby script.rb", true)
        runner.run_ruby_script("script.rb")
      end

      it "does not log status if required" do
        mock(runner).run("ruby script.rb", false)
        runner.run_ruby_script("script.rb", false)
      end
    end

    describe "#thor" do
      it "executes the thor command" do
        mock(runner).run("thor list", true)
        runner.thor(:list, true)
      end

      it "converts extra arguments to command arguments" do
        mock(runner).run("thor list foo bar", true)
        runner.thor(:list, "foo", "bar")
      end

      it "converts options hash to switches" do
        mock(runner).run("thor list foo bar --foo", true)
        runner.thor(:list, "foo", "bar", :foo => true)

        mock(runner).run("thor list --foo 1 2 3", true)
        runner.thor(:list, :foo => [1,2,3])
      end

      it "does not log status if required" do
        mock(runner).run("thor list --foo 1 2 3", false)
        runner.thor(:list, { :foo => [1,2,3] }, false)
      end
    end
  end

  describe 'file manipulation' do
    before(:each) do
      ::FileUtils.rm_rf(destination_root)
      ::FileUtils.cp_r(source_root, destination_root)
    end

    def runner(config={})
      @runner ||= MyCounter.new([], {}, { :root => destination_root }.merge(config))
    end

    def file
      File.join(destination_root, "doc", "README")
    end

    describe "#gsub_file" do
      it "replaces the content in the file" do
        capture(:stdout){ runner.gsub_file("doc/README", "__start__", "START") }
        File.open(file).read.must == "START\nREADME\n__end__\n"
      end

      it "does not replace if pretending" do
        capture(:stdout){ runner(:behavior => :pretend).gsub_file("doc/README", "__start__", "START") }
        File.open(file).read.must == "__start__\nREADME\n__end__\n"
      end

      it "accepts a block" do
        capture(:stdout) do
          runner.gsub_file("doc/README", "__start__"){ |match| match.gsub('__', '').upcase  }
        end
        File.open(file).read.must == "START\nREADME\n__end__\n"
      end

      it "logs status" do
        content = capture(:stdout){ runner.gsub_file("doc/README", "__start__", "START") }
        content.must == "      [GSUB] doc/README\n"
      end

      it "does not log status if required" do
        capture(:stdout) do
          runner.gsub_file(file, "__", false){ |match| match * 2 }
        end.must be_empty
      end
    end

    describe "#append_file" do
      it "appends content to the file" do
        capture(:stdout){ runner.append_file("doc/README", "END\n") }
        File.open(file).read.must == "__start__\nREADME\n__end__\nEND\n"
      end

      it "does not append if pretending" do
        capture(:stdout){ runner(:behavior => :pretend).append_file("doc/README", "END\n") }
        File.open(file).read.must == "__start__\nREADME\n__end__\n"
      end

      it "accepts a block" do
        capture(:stdout) do
          runner.append_file("doc/README"){ "END\n" }
        end
        File.open(file).read.must == "__start__\nREADME\n__end__\nEND\n"
      end

      it "logs status" do
        content = capture(:stdout){ runner.append_file("doc/README", "END") }
        content.must == "    [APPEND] doc/README\n"
      end

      it "does not log status if required" do
        capture(:stdout) do
          runner.append_file("doc/README", nil, false){ "END" }
        end.must be_empty
      end
    end

    describe "#prepend_file" do
      it "prepends content to the file" do
        capture(:stdout){ runner.prepend_file("doc/README", "START\n") }
        File.open(file).read.must == "START\n__start__\nREADME\n__end__\n"
      end

      it "does not prepend if pretending" do
        capture(:stdout){ runner(:behavior => :pretend).prepend_file("doc/README", "START\n") }
        File.open(file).read.must == "__start__\nREADME\n__end__\n"
      end

      it "accepts a block" do
        capture(:stdout) do
          runner.prepend_file("doc/README"){ "START\n" }
        end
        File.open(file).read.must == "START\n__start__\nREADME\n__end__\n"
      end

      it "logs status" do
        content = capture(:stdout){ runner.prepend_file("doc/README", "START") }
        content.must == "   [PREPEND] doc/README\n"
      end

      it "does not log status if required" do
        capture(:stdout) do
          runner.prepend_file("doc/README", nil, false){ "START" }
        end.must be_empty
      end
    end
  end
end
