require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Thor::Shell::Basic do
  def shell
    @shell ||= Thor::Shell::Basic.new
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
      shell.yes?("Should I overwrite it?").must_not be_true
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

  describe "#say_status" do
    it "prints a message to the user with status" do
      mock($stdout).puts("   [CREATED] ~/.thor/task.thor")
      shell.say_status(:created, "~/.thor/task.thor")
    end

    it "always use new line" do
      mock($stdout).puts("   [CREATED] ")
      shell.say_status(:created, "")
    end

    it "does not print a message if base is set to quiet" do
      base = MyCounter.new
      mock(base).options { Hash.new(:quiet => true) }

      shell.base = base
      capture(:stdout) { shell.say_status(:created, "~/.thor/task.thor") }.must be_empty
    end
  end

  describe "#print_list" do
    before(:each) do
      @list = ["abc", "#123", "first three"]
    end

    it "prints a list" do
      content = capture(:stdout){ shell.print_list(@list) }
      content.must == <<-LIST
abc
#123
first three
LIST
    end

    it "prints a list inline" do
      content = capture(:stdout){ shell.print_list(@list, :inline) }
      content.must == <<-LIST
abc, #123, and first three
LIST
    end
  end

  describe "#print_table" do
    before(:each) do
      @table = []
      @table << ["abc", "#123", "first three"]
      @table << ["", "#0", "empty"]
      @table << ["xyz", "#786", "last three"]
    end

    it "prints a table" do
      content = capture(:stdout){ shell.print_table(@table) }
      content.must == <<-TABLE
abc  #123  first three
     #0    empty
xyz  #786  last three
TABLE
    end

    it "prints a table with identation" do
      content = capture(:stdout){ shell.print_table(@table, :ident => 2) }
      content.must == <<-TABLE
  abc  #123  first three
       #0    empty
  xyz  #786  last three
TABLE
    end
  end

  describe "#file_collision" do
    it "shows a menu with options" do
      mock($stdout).print('Overwrite foo? (enter "h" for help) [Ynaqh] ')
      mock($stdin).gets{ 'n' }
      shell.file_collision('foo')
    end

    it "returns false if the user choose no" do
      stub($stdout).print
      mock($stdin).gets{ 'n' }
      shell.file_collision('foo').must be_false
    end

    it "returns true if the user choose yes" do
      stub($stdout).print
      mock($stdin).gets{ 'y' }
      shell.file_collision('foo').must be_true
    end

    it "shows help usage if the user choose help" do
      stub($stdout).print
      mock($stdin).gets{ 'h' }
      mock($stdin).gets{ 'n' }
      help = capture(:stdout){ shell.file_collision('foo') }
      help.must =~ /h \- help, show this help/
    end

    it "quits if the user choose quit" do
      stub($stdout).print
      mock($stdout).puts('Aborting...')
      mock($stdin).gets{ 'q' }

      lambda {
        shell.file_collision('foo')
      }.must raise_error(SystemExit)
    end

    it "always returns true if the user choose always" do
      mock($stdout).print('Overwrite foo? (enter "h" for help) [Ynaqh] ')
      mock($stdin).gets{ 'a' }

      shell.file_collision('foo').must be_true

      dont_allow($stdout).print
      shell.file_collision('foo').must be_true
    end

    describe "when a block is given" do
      it "displays diff options to the user" do
        mock($stdout).print('Overwrite foo? (enter "h" for help) [Ynaqdh] ')
        mock($stdin).gets{ 's' }
        shell.file_collision('foo'){ }
      end

      it "invokes the diff command" do
        stub($stdout).print
        mock($stdin).gets{ 'd' }
        mock($stdin).gets{ 'n' }
        stub(shell).`{ 'diff_output' }

        capture(:stdout){ shell.file_collision('foo'){ } }.must =~ /diff_output/
      end
    end
  end
end
