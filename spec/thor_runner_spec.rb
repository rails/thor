require File.expand_path(File.dirname(__FILE__) + "/spec_helper")
require 'thor/runner'

describe Thor::Runner do
  describe "#help" do
    it "shows information about Thor::Runner itself" do
      capture(:stdout){ Thor::Runner.start(["help"]) }.must =~ /list the available thor tasks/
    end

    it "shows information about an specific Thor::Runner task" do
      content = capture(:stdout){ Thor::Runner.start(["help", "list"]) }
      content.must =~ /list the available thor tasks/
      content.must_not =~ /help \[TASK\]/
    end

    it "shows information about a specific Thor class" do
      content = capture(:stdout){ Thor::Runner.start(["help", "my_script"]) }
      content.must =~ /zoo +# zoo around/
    end

    it "shows information about an specific task from an specific Thor class" do
      content = capture(:stdout){ Thor::Runner.start(["help", "my_script:zoo"]) }
      content.must =~ /zoo around/
      content.must_not =~ /help \[TASK\]/
    end

    it "shows information about a specific Thor::Generator class" do
      content = capture(:stdout){ Thor::Runner.start(["help", "my_counter"]) }
      content.must =~ /my_counter N \[N\]/
    end

    it "raises error if a class/task cannot be found" do
      content = capture(:stderr){ Thor::Runner.start(["help", "unknown"]) }
      content.must =~ /could not find Thor class or task 'unknown'/
    end
  end

  describe "#start" do
    it "invokes a task from Thor::Runner" do
      ARGV.replace ["list"]
      capture(:stdout){ Thor::Runner.start }.must =~ /my_counter N \[N\] \[\-\-third=N\]/
    end

    it "invokes a task from a specific Thor class" do
      ARGV.replace ["my_script:zoo"]
      Thor::Runner.start.must be_true
    end

    it "invokes the default task from a specific Thor class if none is specified" do
      ARGV.replace ["my_script"]
      Thor::Runner.start.must == "default task"
    end

    it "invokes the default task from a specific Thor class if none is specified" do
      ARGV.replace ["my_script"]
      Thor::Runner.start.must == "default task"
    end

    it "forwads arguments to the invoked task" do
      ARGV.replace ["my_script:animal", "horse"]
      Thor::Runner.start.must == ["horse"]
    end

    it "invokes tasks through shortcuts" do
      ARGV.replace ["my_script", "-T", "horse"]
      Thor::Runner.start.must == ["horse"]
    end

    it "invokes a specific Thor::Generator" do
      ARGV.replace ["my_counter", "1", "2", "--third", "3"]
      Thor::Runner.start.must == [1, 2, 3]
    end

    it "raises an error if class/task can't be found" do
      ARGV.replace ["unknown"]
      capture(:stderr){ Thor::Runner.start }.must =~ /could not find Thor class or task 'unknown'/
    end
  end
end
