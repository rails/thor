require "helper"

describe Thor::Actions do
  def runner(options = {})
    @runner ||= MyCounter.new([1], options, destination_root: destination_root)
  end

  def action(*args, &block)
    capture(:stdout) { runner.send(*args, &block) }
  end

  def file
    File.join(destination_root, "foo")
  end

  describe "on include" do
    it "adds runtime options to the base class" do
      expect(MyCounter.class_options.keys).to include(:pretend)
      expect(MyCounter.class_options.keys).to include(:force)
      expect(MyCounter.class_options.keys).to include(:quiet)
      expect(MyCounter.class_options.keys).to include(:skip)
    end
  end

  describe "#initialize" do
    it "has default behavior invoke" do
      expect(runner.behavior).to eq(:invoke)
    end

    it "can have behavior revoke" do
      expect(MyCounter.new([1], {}, behavior: :revoke).behavior).to eq(:revoke)
    end

    it "when behavior is set to force, overwrite options" do
      runner = MyCounter.new([1], {force: false, skip: true}, behavior: :force)
      expect(runner.behavior).to eq(:invoke)
      expect(runner.options.force).to be true
      expect(runner.options.skip).not_to be true
    end

    it "when behavior is set to skip, overwrite options" do
      runner = MyCounter.new([1], %w(--force), behavior: :skip)
      expect(runner.behavior).to eq(:invoke)
      expect(runner.options.force).not_to be true
      expect(runner.options.skip).to be true
    end
  end

  describe "accessors" do
    describe "#destination_root=" do
      it "gets the current directory and expands the path to set the root" do
        base = MyCounter.new([1])
        base.destination_root = "here"
        expect(base.destination_root).to eq(File.expand_path(File.join(File.dirname(__FILE__), "..", "here")))
      end

      it "does not use the current directory if one is given" do
        root = File.expand_path("/")
        base = MyCounter.new([1])
        base.destination_root = root
        expect(base.destination_root).to eq(root)
      end

      it "uses the current directory if none is given" do
        base = MyCounter.new([1])
        expect(base.destination_root).to eq(File.expand_path(File.join(File.dirname(__FILE__), "..")))
      end
    end

    describe "#relative_to_original_destination_root" do
      it "returns the path relative to the absolute root" do
        expect(runner.relative_to_original_destination_root(file)).to eq("foo")
      end

      it "does not remove dot if required" do
        expect(runner.relative_to_original_destination_root(file, false)).to eq("./foo")
      end

      it "always use the absolute root" do
        runner.inside("foo") do
          expect(runner.relative_to_original_destination_root(file)).to eq("foo")
        end
      end

      it "creates proper relative paths for absolute file location" do
        expect(runner.relative_to_original_destination_root("/test/file")).to eq("/test/file")
      end

      it "doesn't remove the root path from the absolute path if it is not at the beginning" do
        runner.destination_root = "/app"
        expect(runner.relative_to_original_destination_root("/something/app/project")).to eq("/something/app/project")
      end

      it "doesn't removes the root path from the absolute path only if it is only the partial name of the directory" do
        runner.destination_root = "/app"
        expect(runner.relative_to_original_destination_root("/application/project")).to eq("/application/project")
      end

      it "removes the root path from the absolute path only once" do
        runner.destination_root = "/app"
        expect(runner.relative_to_original_destination_root("/app/app/project")).to eq("app/project")
      end

      it "does not fail with files containing regexp characters" do
        runner = MyCounter.new([1], {}, destination_root: File.join(destination_root, "fo[o-b]ar"))
        expect(runner.relative_to_original_destination_root("bar")).to eq("bar")
      end

      describe "#source_paths_for_search" do
        it "add source_root to source_paths_for_search" do
          expect(MyCounter.source_paths_for_search).to include(File.expand_path("fixtures", File.dirname(__FILE__)))
        end

        it "keeps only current source root in source paths" do
          expect(ClearCounter.source_paths_for_search).to include(File.expand_path("fixtures/bundle", File.dirname(__FILE__)))
          expect(ClearCounter.source_paths_for_search).not_to include(File.expand_path("fixtures", File.dirname(__FILE__)))
        end

        it "customized source paths should be before source roots" do
          expect(ClearCounter.source_paths_for_search[0]).to eq(File.expand_path("fixtures/doc", File.dirname(__FILE__)))
          expect(ClearCounter.source_paths_for_search[1]).to eq(File.expand_path("fixtures/bundle", File.dirname(__FILE__)))
        end

        it "keeps inherited source paths at the end" do
          expect(ClearCounter.source_paths_for_search.last).to eq(File.expand_path("fixtures/broken", File.dirname(__FILE__)))
        end
      end
    end

    describe "#find_in_source_paths" do
      it "raises an error if source path is empty" do
        expect do
          A.new.find_in_source_paths("foo")
        end.to raise_error(Thor::Error, /Currently you have no source paths/)
      end

      it "finds a template inside the source path" do
        expect(runner.find_in_source_paths("doc")).to eq(File.expand_path("doc", source_root))
        expect { runner.find_in_source_paths("README") }.to raise_error(Thor::Error, /Could not find "README" in any of your source paths./)

        new_path = File.join(source_root, "doc")
        runner.instance_variable_set(:@source_paths, nil)
        runner.source_paths.unshift(new_path)
        expect(runner.find_in_source_paths("README")).to eq(File.expand_path("README", new_path))
      end
    end
  end

  describe "#inside" do
    it "executes the block inside the given folder" do
      runner.inside("foo") do
        expect(Dir.pwd).to eq(file)
      end
    end

    it "changes the base root" do
      runner.inside("foo") do
        expect(runner.destination_root).to eq(file)
      end
    end

    it "creates the directory if it does not exist" do
      runner.inside("foo") do
        expect(File.exist?(file)).to be true
      end
    end

    it "returns the value yielded by the block" do
      expect(runner.inside("foo") { 123 }).to eq(123)
    end

    describe "when pretending" do
      it "no directories should be created" do
        runner.inside("bar", pretend: true) {}
        expect(File.exist?("bar")).to be false
      end

      it "returns the value yielded by the block" do
        expect(runner.inside("foo") { 123 }).to eq(123)
      end
    end

    describe "when verbose" do
      it "logs status" do
        expect(capture(:stdout) do
          runner.inside("foo", verbose: true) {}
        end).to match(/inside  foo/)
      end

      it "uses padding in next status" do
        expect(capture(:stdout) do
          runner.inside("foo", verbose: true) do
            runner.say_status :cool, :padding
          end
        end).to match(/cool    padding/)
      end

      it "removes padding after block" do
        expect(capture(:stdout) do
          runner.inside("foo", verbose: true) {}
          runner.say_status :no, :padding
        end).to match(/no  padding/)
      end
    end
  end

  describe "#in_root" do
    it "executes the block in the root folder" do
      runner.inside("foo") do
        runner.in_root { expect(Dir.pwd).to eq(destination_root) }
      end
    end

    it "changes the base root" do
      runner.inside("foo") do
        runner.in_root { expect(runner.destination_root).to eq(destination_root) }
      end
    end

    it "returns to the previous state" do
      runner.inside("foo") do
        runner.in_root {}
        expect(runner.destination_root).to eq(file)
      end
    end
  end

  describe "#apply" do
    before do
      @template = <<-TEMPLATE.dup
        @foo = "FOO"
        say_status :cool, :padding
      TEMPLATE
      allow(@template).to receive(:read).and_return(@template)

      @file = "/"
      allow(File).to receive(:open).and_return(@template)
    end

    it "accepts a URL as the path" do
      @file = "http://gist.github.com/103208.txt"
      stub_request(:get, @file)

      expect(runner).to receive(:apply).with(@file).and_return(@template)
      action(:apply, @file)
    end

    it "accepts a secure URL as the path" do
      @file = "https://gist.github.com/103208.txt"
      stub_request(:get, @file)

      expect(runner).to receive(:apply).with(@file).and_return(@template)
      action(:apply, @file)
    end

    it "accepts a local file path with spaces" do
      @file = File.expand_path("fixtures/path with spaces", File.dirname(__FILE__))
      expect(File).to receive(:open).with(@file).and_return(@template)
      action(:apply, @file)
    end

    it "opens a file and executes its content in the instance binding" do
      action :apply, @file
      expect(runner.instance_variable_get("@foo")).to eq("FOO")
    end

    it "applies padding to the content inside the file" do
      expect(action(:apply, @file)).to match(/cool    padding/)
    end

    it "logs its status" do
      expect(action(:apply, @file)).to match(/       apply  #{@file}\n/)
    end

    it "does not log status" do
      content = action(:apply, @file, verbose: false)
      expect(content).to match(/cool  padding/)
      expect(content).not_to match(/apply http/)
    end
  end

  describe "#run" do
    describe "when not pretending" do
      before do
        expect(runner).to receive(:system).with("ls")
      end

      it "executes the command given" do
        action :run, "ls"
      end

      it "logs status" do
        expect(action(:run, "ls")).to eq("         run  ls from \".\"\n")
      end

      it "does not log status if required" do
        expect(action(:run, "ls", verbose: false)).to be_empty
      end

      it "accepts a color as status" do
        expect(runner.shell).to receive(:say_status).with(:run, 'ls from "."', :yellow)
        action :run, "ls", verbose: :yellow
      end
    end

    describe "when pretending" do
      it "doesn't execute the command" do
        runner = MyCounter.new([1], %w(--pretend))
        expect(runner).not_to receive(:system)
        runner.run("ls", verbose: false)
      end
    end

    describe "when not capturing" do
      it "aborts when abort_on_failure is given and command fails" do
        expect { action :run, "false", abort_on_failure: true }.to raise_error(SystemExit)
      end

      it "succeeds when abort_on_failure is given and command succeeds" do
        expect { action :run, "true", abort_on_failure: true }.not_to raise_error
      end

      it "supports env option" do
        expect { action :run, "echo $BAR", env: {"BAR" => "foo"} }.to output("foo\n").to_stdout_from_any_process
      end
    end

    describe "when capturing" do
      it "aborts when abort_on_failure is given, capture is given and command fails" do
        expect { action :run, "false", abort_on_failure: true, capture: true }.to raise_error(SystemExit)
      end

      it "succeeds when abort_on_failure is given and command succeeds" do
        expect { action :run, "true", abort_on_failure: true, capture: true }.not_to raise_error
      end

      it "supports env option" do
        silence(:stdout) do
          expect(runner.run "echo $BAR", env: {"BAR" => "foo"}, capture: true).to eq("foo\n")
        end
      end
    end

    context "exit_on_failure? is true" do
      before do
        allow(MyCounter).to receive(:exit_on_failure?).and_return(true)
      end

      it "aborts when command fails even if abort_on_failure is not given" do
        expect { action :run, "false" }.to raise_error(SystemExit)
      end

      it "does not abort when abort_on_failure is false even if the command fails" do
        expect { action :run, "false", abort_on_failure: false }.not_to raise_error
      end
    end
  end

  describe "#run_ruby_script" do
    before do
      allow(Thor::Util).to receive(:ruby_command).and_return("/opt/jruby")
      expect(runner).to receive(:system).with("/opt/jruby script.rb")
    end

    it "executes the ruby script" do
      action :run_ruby_script, "script.rb"
    end

    it "logs status" do
      expect(action(:run_ruby_script, "script.rb")).to eq("         run  jruby script.rb from \".\"\n")
    end

    it "does not log status if required" do
      expect(action(:run_ruby_script, "script.rb", verbose: false)).to be_empty
    end
  end

  describe "#thor" do
    it "executes the thor command" do
      expect(runner).to receive(:system).with("thor list")
      action :thor, :list, verbose: true
    end

    it "converts extra arguments to command arguments" do
      expect(runner).to receive(:system).with("thor list foo bar")
      action :thor, :list, "foo", "bar"
    end

    it "converts options hash to switches" do
      expect(runner).to receive(:system).with("thor list foo bar --foo")
      action :thor, :list, "foo", "bar", foo: true

      expect(runner).to receive(:system).with("thor list --foo 1 2 3")
      action :thor, :list, foo: [1, 2, 3]
    end

    it "logs status" do
      expect(runner).to receive(:system).with("thor list")
      expect(action(:thor, :list)).to eq("         run  thor list from \".\"\n")
    end

    it "does not log status if required" do
      expect(runner).to receive(:system).with("thor list --foo 1 2 3")
      expect(action(:thor, :list, foo: [1, 2, 3], verbose: false)).to be_empty
    end

    it "captures the output when :capture is given" do
      expect(runner).to receive(:run).with("list", hash_including(capture: true))
      action :thor, :list, capture: true
    end
  end
end
