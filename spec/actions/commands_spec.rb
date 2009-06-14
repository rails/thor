require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

class MyRunner < Thor
  include Actions
end

describe Thor::Actions, 'commands' do
  def runner(config={})
    @runner ||= MyRunner.new([], {}, { :root => destination_root }.merge(config))
  end

  def file
    File.join(destination_root, "foo")
  end

  describe "#run" do
    it "executes the command given" do
      mock(runner).`("ls"){ 'spec' } # To avoid highlighting issues `
      capture(:stdout) { runner.run('ls') }
    end

    it "does not execute the command if pretending given" do
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

  describe "#git" do
    describe "when a symbol is given" do
      it "executes the git command" do
        mock(runner).run("git init", true)
        runner.git(:init)
      end

      it "does not log status if required" do
        mock(runner).run("git init", false)
        runner.git(:init, false)
      end
    end

    describe "when a hash is given" do
      it "executes several commands when a hash is given" do
        mock(runner).run("git add foo", true)
        mock(runner).run("git remove bar", true)
        runner.git(:add => "foo", :remove => "bar")
      end

      it "does not log status if required" do
        mock(runner).run("git add foo", false)
        runner.git({ :add => "foo" }, false)
      end
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
