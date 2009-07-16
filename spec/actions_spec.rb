require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Thor::Actions do
  def runner(options={})
    @runner ||= MyCounter.new([1], options, { :destination_root => destination_root })
  end

  def action(*args, &block)
    capture(:stdout){ runner.send(*args, &block) }
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
      MyCounter.new([1], {}, :behavior => :revoke).behavior.must == :revoke
    end

    it "when behavior is set to force, overwrite options" do
      runner = MyCounter.new([1], { :force => false, :skip => true }, :behavior => :force)
      runner.behavior.must == :invoke
      runner.options.force.must be_true
      runner.options.skip.must_not be_true
    end

    it "when behavior is set to skip, overwrite options" do
      runner = MyCounter.new([1], ["--force"], :behavior => :skip)
      runner.behavior.must == :invoke
      runner.options.force.must_not be_true
      runner.options.skip.must be_true
    end
  end

  describe "accessors" do
    describe "#destination_root=" do
      it "gets the current directory and expands the path to set the root" do
        base = MyCounter.new([1])
        base.destination_root = "here"
        base.destination_root.must == File.expand_path(File.join(File.dirname(__FILE__), "..", "here"))
      end

      it "does not use the current directory if one is given" do
        base = MyCounter.new([1])
        base.destination_root = "/"
        base.destination_root.must == "/"
      end

      it "uses the current directory if none is given" do
        base = MyCounter.new([1])
        base.destination_root.must == File.expand_path(File.join(File.dirname(__FILE__), ".."))
      end
    end

    describe "#relative_to_original_destination_root" do
      it "returns the path relative to the absolute root" do
        runner.relative_to_original_destination_root(file).must == "foo"
      end

      it "does not remove dot if required" do
        runner.relative_to_original_destination_root(file, false).must == "./foo"
      end

      it "always use the absolute root" do
        runner.inside("foo") do
          runner.relative_to_original_destination_root(file).must == "foo"
        end
      end

      describe "#source_paths_for_search" do
        it "add source_root to source_paths_for_search" do
          MyCounter.source_paths_for_search.must include(File.expand_path("fixtures", File.dirname(__FILE__)))
        end

        it "keeps only current source root in source paths" do
          ClearCounter.source_paths_for_search.must include(File.expand_path("fixtures/bundle", File.dirname(__FILE__)))
          ClearCounter.source_paths_for_search.must_not include(File.expand_path("fixtures", File.dirname(__FILE__)))
        end

        it "customized source paths should be before source roots" do
          ClearCounter.source_paths_for_search[0].must == File.expand_path("fixtures/doc", File.dirname(__FILE__))
          ClearCounter.source_paths_for_search[1].must == File.expand_path("fixtures/bundle", File.dirname(__FILE__))
        end

        it "keeps inherited source paths at the end" do
          ClearCounter.source_paths_for_search.last.must == File.expand_path("fixtures/broken", File.dirname(__FILE__))
        end
      end
    end

    describe "#find_in_source_paths" do
      it "raises an error if source path is empty" do
        lambda {
          A.new.find_in_source_paths("foo")
        }.must raise_error(Thor::Error, /You don't have any source path defined for class A/)
      end

      it "finds a template inside the source path" do
        runner.find_in_source_paths("doc").must == File.expand_path("doc", source_root)
        lambda { runner.find_in_source_paths("README") }.must raise_error

        new_path = File.join(source_root, "doc")
        runner.class.source_paths.unshift(new_path)
        runner.class.clear_source_paths_for_search
        runner.find_in_source_paths("README").must == File.expand_path("README", new_path)
        runner.class.source_paths.shift
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
      runner.inside("foo") do
        runner.destination_root.must == file
      end
    end

    it "creates the directory if it does not exist" do
      runner.inside("foo") do
        File.exists?(file).must be_true
      end
    end
  end

  describe "#inside_with_padding" do
    it "behaves like #inside" do
      capture(:stdout) do
        runner.inside_with_padding("foo") do
          Dir.pwd.must == file
        end
      end
    end

    it "logs status" do
      capture(:stdout) do
        runner.inside_with_padding("foo") {}
      end.must =~ /inside  foo/
    end

    it "uses padding in next status" do
      capture(:stdout) do
        runner.inside_with_padding("foo") do
          runner.say_status :cool, :padding
        end
      end.must =~ /cool    padding/
    end

    it "removes padding after block" do
      capture(:stdout) do
        runner.inside_with_padding("foo") {}
        runner.say_status :no, :padding
      end.must =~ /no  padding/
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
        runner.in_root { runner.destination_root.must == destination_root }
      end
    end

    it "returns to the previous state" do
      runner.inside("foo") do
        runner.in_root { }
        runner.destination_root.must == file
      end
    end
  end

  describe "#run" do
    before(:each) do
      mock(runner).`("ls") #`
    end

    it "executes the command given" do
      action :run, "ls"
    end

    it "logs status" do
      action(:run, "ls").must == "         run  \"ls\" from .\n"
    end

    it "does not log status if required" do
      action(:run, "ls", :verbose => false).must be_empty
    end

    it "accepts a color as status" do
      mock(runner.shell).say_status(:run, '"ls" from .', :yellow)
      action :run, "ls", :verbose => :yellow
    end
  end

  describe "#run_ruby_script" do
    before(:each) do
      stub(Thor::Util).ruby_command{ "/opt/jruby" }
      mock(runner).`("/opt/jruby script.rb") #`
    end

    it "executes the ruby script" do
      action :run_ruby_script, "script.rb"
    end

    it "logs status" do
      action(:run_ruby_script, "script.rb").must == "       jruby  script.rb\n"
    end

    it "does not log status if required" do
      action(:run_ruby_script, "script.rb", :verbose => false).must be_empty
    end
  end

  describe "#thor" do
    it "executes the thor command" do
      mock(runner).run("thor list", :verbose => false)
      action :thor, :list, :verbose => true
    end

    it "converts extra arguments to command arguments" do
      mock(runner).run("thor list foo bar", :verbose => false)
      action :thor, :list, "foo", "bar"
    end

    it "converts options hash to switches" do
      mock(runner).run("thor list foo bar --foo", :verbose => false)
      action :thor, :list, "foo", "bar", :foo => true

      mock(runner).run("thor list --foo 1 2 3", :verbose => false)
      action :thor, :list, :foo => [1,2,3]
    end

    it "logs status" do
      mock(runner).run("thor list", :verbose => false)
      action(:thor, :list).must == "        thor  list\n"
    end

    it "does not log status if required" do
      mock(runner).run("thor list --foo 1 2 3", :verbose => false)
      action :thor, :list, :foo => [1,2,3], :verbose => false
    end
  end
end
