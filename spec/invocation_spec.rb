require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'thor/base'

describe Thor::Invocation do
  describe "#invoke" do
    it "invokes a task inside another task" do
      capture(:stdout){ A.new.invoke(:two) }.must == "2\n3\n"
    end

    it "invokes a task just once" do
      capture(:stdout){ A.new.invoke(:one) }.must == "1\n2\n3\n"
    end

    it "invokes a task just once even if they belongs to different classes" do
      capture(:stdout){ Defined.new.invoke(:one) }.must == "1\n2\n3\n4\n5\n"
    end

    it "invokes a task with arguments" do
      A.new.invoke(:five, [5]).must be_true
      A.new.invoke(:five, [7]).must be_false
    end

    it "invokes the default task if none is given to a Thor class" do
      content = capture(:stdout){ A.new.invoke("b") }
      content.must =~ /Tasks/
      content.must =~ /LAST_NAME/
    end

    it "accepts a class as argument without a task to invoke" do
      content = capture(:stdout){ A.new.invoke(B) }
      content.must =~ /Tasks/
      content.must =~ /LAST_NAME/
    end

    it "accepts a class as argument with a task to invoke" do
      base = A.new([], :last_name => "Valim")
      base.invoke(B, :one, ["Jose"]).must == "Valim, Jose"
    end

    it "allows customized options to be given" do
      base = A.new([], :last_name => "Wrong")
      base.invoke(B, :one, ["Jose"], :last_name => "Valim").must == "Valim, Jose"
    end

    it "reparses options in the new class" do
      A.start(["invoker", "--last-name", "Valim"]).must == "Valim, Jose"
    end

    it "shares initialize options with invoked class" do
      A.new([], :foo => :bar).invoke("b:two").must == { "foo" => :bar }
    end

    it "dump configuration values to be used in the invoked class" do
      base = A.new
      base.invoke("b:three").shell.must == base.shell
    end

    it "allow extra configuration values to be given" do
      base, shell = A.new, Thor::Base.shell.new
      base.invoke("b:three", [], {}, :shell => shell).shell.must == shell
    end

    it "invokes a Thor::Group and all of its tasks" do
      capture(:stdout){ A.new.invoke(:c) }.must == "1\n2\n3\n"
    end

    it "does not invoke a Thor::Group twice" do
      base = A.new
      silence(:stdout){ base.invoke(:c) }
      capture(:stdout){ base.invoke(:c) }.must be_empty
    end

    it "does not invoke any of Thor::Group tasks twice" do
      base = A.new
      silence(:stdout){ base.invoke(:c) }
      capture(:stdout){ base.invoke("c:one") }.must be_empty
    end

    it "raises Thor::UndefinedTaskError if the task can't be found" do
      lambda do
        A.new.invoke("foo:bar")
      end.must raise_error(Thor::UndefinedTaskError)
    end

    it "raises Thor::UndefinedTaskError if the task can't be found even if all tasks where already executed" do
      base = C.new
      silence(:stdout){ base.invoke_all }

      lambda do
        base.invoke("foo:bar")
      end.must raise_error(Thor::UndefinedTaskError)
    end

    it "raises an error if a non Thor class is given" do
      lambda do
        A.new.invoke(Object)
      end.must raise_error(RuntimeError, "Expected Thor class, got Object")
    end
  end
end
