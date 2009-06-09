require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Thor::Shells::Basic do
  def shell
    Thor::Shells::Basic
  end

  describe "#ask" do
    it "prints a message to the user and gets the response" do
      mock($stdout).print("Should I overwrite it? ")
      mock($stdin).gets{ "Sure" }
      shell.ask("Should I overwrite it?").must == "Sure"
    end
  end

  describe "#yes?" do
    it "asks the user and returns true if the user replies yes" do
      mock($stdout).print("Should I overwrite it? ")
      mock($stdin).gets{ "y" }
      shell.yes?("Should I overwrite it?").must be_true

      mock($stdout).print("Should I overwrite it? ")
      mock($stdin).gets{ "n" }
      shell.yes?("Should I overwrite it?").must be_false
    end
  end

  describe "#no?" do
    it "asks the user and returns true if the user replies no" do
      mock($stdout).print("Should I overwrite it? ")
      mock($stdin).gets{ "n" }
      shell.no?("Should I overwrite it?").must be_true

      mock($stdout).print("Should I overwrite it? ")
      mock($stdin).gets{ "Yes" }
      shell.no?("Should I overwrite it?").must be_false
    end
  end

  describe "#say" do
    it "prints a message to the user" do
      mock($stdout).puts("Running...")
      shell.say("Running...")
    end

    it "prints a message to the user without new line if it ends with a whitespace" do
      mock($stdout).print("Running... ")
      shell.say("Running... ")
    end
  end

  describe "#table" do
    before(:each) do
      @table = []
      @table << ["abc", "#123", "first three"]
      @table << ["", "#0", "empty"]
      @table << ["xyz", "#786", "last three"]
    end

    it "prints a table" do
      content = capture(:stdout){ shell.table(@table) }
      content.must == <<-TABLE
abc  #123  first three
     #0    empty
xyz  #786  last three
TABLE
    end

    it "prints a table with identation" do
      content = capture(:stdout){ shell.table(@table, :ident => 2) }
      content.must == <<-TABLE
  abc  #123  first three
       #0    empty
  xyz  #786  last three
TABLE
    end
  end
end
