require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'thor/base'

describe Thor::Invocation do
  describe "#invoke" do
    it "invokes a task inside another task" do
      expect(capture(:stdout) { A.new.invoke(:two) }).to eq("2\n3\n")
    end

    it "invokes a task just once" do
      expect(capture(:stdout) { A.new.invoke(:one) }).to eq("1\n2\n3\n")
    end

    it "invokes a task just once even if they belongs to different classes" do
      expect(capture(:stdout) { Defined.new.invoke(:one) }).to eq("1\n2\n3\n4\n5\n")
    end

    it "invokes a task with arguments" do
      expect(A.new.invoke(:five, [5])).to be_true
      expect(A.new.invoke(:five, [7])).to be_false
    end

    it "invokes the default task if none is given to a Thor class" do
      content = capture(:stdout) { A.new.invoke("b") }
      expect(content).to match(/Tasks/)
      expect(content).to match(/LAST_NAME/)
    end

    it "accepts a class as argument without a task to invoke" do
      content = capture(:stdout) { A.new.invoke(B) }
      expect(content).to match(/Tasks/)
      expect(content).to match(/LAST_NAME/)
    end

    it "accepts a class as argument with a task to invoke" do
      base = A.new([], :last_name => "Valim")
      expect(base.invoke(B, :one, ["Jose"])).to eq("Valim, Jose")
    end

    it "allows customized options to be given" do
      base = A.new([], :last_name => "Wrong")
      expect(base.invoke(B, :one, ["Jose"], :last_name => "Valim")).to eq("Valim, Jose")
    end

    it "reparses options in the new class" do
      expect(A.start(["invoker", "--last-name", "Valim"])).to eq("Valim, Jose")
    end

    it "shares initialize options with invoked class" do
      expect(A.new([], :foo => :bar).invoke("b:two")).to eq({ "foo" => :bar })
    end

    it "dump configuration values to be used in the invoked class" do
      base = A.new
      expect(base.invoke("b:three").shell).to eq(base.shell)
    end

    it "allow extra configuration values to be given" do
      base, shell = A.new, Thor::Base.shell.new
      expect(base.invoke("b:three", [], {}, :shell => shell).shell).to eq(shell)
    end

    it "invokes a Thor::Group and all of its tasks" do
      expect(capture(:stdout) { A.new.invoke(:c) }).to eq("1\n2\n3\n")
    end

    it "does not invoke a Thor::Group twice" do
      base = A.new
      silence(:stdout){ base.invoke(:c) }
      expect(capture(:stdout) { base.invoke(:c) }).to be_empty
    end

    it "does not invoke any of Thor::Group tasks twice" do
      base = A.new
      silence(:stdout){ base.invoke(:c) }
      expect(capture(:stdout) { base.invoke("c:one") }).to be_empty
    end

    it "raises Thor::UndefinedTaskError if the task can't be found" do
      expect {
        A.new.invoke("foo:bar")
      }.to raise_error(Thor::UndefinedTaskError)
    end

    it "raises Thor::UndefinedTaskError if the task can't be found even if all tasks where already executed" do
      base = C.new
      silence(:stdout){ base.invoke_all }

      expect {
        base.invoke("foo:bar")
      }.to raise_error(Thor::UndefinedTaskError)
    end

    it "raises an error if a non Thor class is given" do
      expect {
        A.new.invoke(Object)
      }.to raise_error(RuntimeError, "Expected Thor class, got Object")
    end
  end
end
