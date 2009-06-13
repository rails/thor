require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'thor/runner'

class MyRunner < Thor
  include Actions
end

describe Thor::Actions do
  def runner(config={})
    @runner ||= MyRunner.new([], {}, { :root => destination_root }.merge(config))
  end

  def file
    File.join(destination_root, "foo")
  end

  describe "#initialize" do
    it "has default behavior invoke" do
      runner.behavior.must == :invoke
    end

    it "can have behavior revoke" do
      runner(:behavior => :revoke).behavior.must == :revoke
    end

    it "goes to the root if in_root is given" do
      begin
        runner :in_root => true
        Dir.pwd.must == destination_root
      ensure
        FileUtils.cd(File.join(destination_root, '..', '..'))
      end
    end

    it "creates the root folder if it does not exist and in_root is given" do
      begin
        runner :in_root => true, :root => file
        Dir.pwd.must == file
        File.exists?(file).must be_true
      ensure
        FileUtils.cd(File.join(destination_root, '..', '..'))
      end
    end

    %w(skip force pretend).each do |behavior|
      it "accepts #{behavior.to_sym} as behavior" do
        thor = runner(:behavior => behavior.to_sym)
        thor.behavior.must == :invoke
        thor.options.send(:"#{behavior}?").must be_true
      end

      it "overwrites options values with configuration values" do
        thor = MyRunner.new([], { behavior => false }, :behavior => behavior.to_sym)
        thor.options.send(:"#{behavior}?").must be_true
      end
    end
  end

  describe "#root=" do
    it "gets the current directory and expands the path to set the root" do
      base = MyRunner.new
      base.root = "here"
      base.root.must == File.expand_path(File.join(File.dirname(__FILE__), "..", "here"))
    end

    it "does not use the current directory if one is given" do
      base = MyRunner.new
      base.root = "/"
      base.root.must == "/"
    end

    it "uses the current directory if none is given" do
      MyRunner.new.root.must == File.expand_path(File.join(File.dirname(__FILE__), ".."))
    end
  end

  describe "#source_root" do
    it "raises an error if source root is not specified" do
      lambda {
        runner.send(:source_root)
      }.must raise_error(NoMethodError, "You have to specify the class method source_root in your thor class.")
    end
  end

  describe "#inside" do
    it "executes the block inside the given folder" do
      capture(:stdout) do
        runner.inside("foo") do
          Dir.pwd.must ==  file
        end
      end
    end

    it "creates the directory if it does not exist" do
      capture(:stdout) do
        runner.inside("foo") do
          File.exists?(file).must be_true
        end
      end
    end

    it "logs status" do
      capture(:stdout) do
        runner.inside("foo") do
          File.exists?(file).must be_true
        end
      end.must == "    [INSIDE] #{file}\n"
    end

    it "does not log status if required" do
      capture(:stdout) do
        runner.inside("foo", false) do
          File.exists?(file).must be_true
        end
      end.must be_empty
    end
  end

  describe "#in_root" do
    it "executes the block in the root folder" do
      capture(:stdout) do
        runner.inside("foo") do
          runner.in_root { Dir.pwd.must == destination_root }
        end
      end
    end
  end

  describe "#run" do
    before(:each) do
            mock(runner).`("ls"){ 'spec' } # To avoid highlighting issues `
    end

    it "executes the command given" do
      capture(:stdout) { runner.run('ls') }
    end

    it "logs status" do
      capture(:stdout) { runner.run('ls') }.must == "   [RUNNING] ls from #{Dir.pwd}\n"
    end

    it "does not log status" do
      capture(:stdout) { runner.run('ls', false) }.must be_empty
    end
  end
end
