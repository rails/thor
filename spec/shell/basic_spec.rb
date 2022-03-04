# coding: utf-8
require "helper"

describe Thor::Shell::Basic do
  def shell
    @shell ||= Thor::Shell::Basic.new
  end

  describe "#padding" do
    it "cannot be set to below zero" do
      shell.padding = 10
      expect(shell.padding).to eq(10)

      shell.padding = -1
      expect(shell.padding).to eq(0)
    end
  end

  describe "#indent" do
    it "sets the padding temporarily" do
      shell.indent { expect(shell.padding).to eq(1) }
      expect(shell.padding).to eq(0)
    end

    it "derives padding from original value" do
      shell.padding = 6
      shell.indent { expect(shell.padding).to eq(7) }
    end

    it "accepts custom indentation amounts" do
      shell.indent(6) do
        expect(shell.padding).to eq(6)
      end
    end

    it "increases the padding when nested" do
      shell.indent do
        expect(shell.padding).to eq(1)

        shell.indent do
          expect(shell.padding).to eq(2)
        end
      end
      expect(shell.padding).to eq(0)
    end
  end

  describe "#ask" do
    it "prints a message to the user and gets the response" do
      expect(Thor::LineEditor).to receive(:readline).with("Should I overwrite it? ", {}).and_return("Sure")
      expect(shell.ask("Should I overwrite it?")).to eq("Sure")
    end

    it "prints a message to the user prefixed with the current padding" do
      expect(Thor::LineEditor).to receive(:readline).with("    Enter your name: ", {}).and_return("George")
      shell.padding = 2
      shell.ask("Enter your name:")
    end

    it "prints a message and returns nil if EOF is given as input" do
      expect(Thor::LineEditor).to receive(:readline).with(" ", {}).and_return(nil)
      expect(shell.ask("")).to eq(nil)
    end

    it "prints a message to the user and does not echo stdin if the echo option is set to false" do
      expect($stdout).to receive(:print).with('What\'s your password? ')
      expect($stdin).to receive(:noecho).and_return("mysecretpass")
      expect(shell.ask("What's your password?", :echo => false)).to eq("mysecretpass")
    end

    it "prints a message to the user with the available options, expects case-sensitive matching, and determines the correctness of the answer" do
      flavors = %w(strawberry chocolate vanilla)
      expect(Thor::LineEditor).to receive(:readline).with('What\'s your favorite Neopolitan flavor? [strawberry, chocolate, vanilla] ', {:limited_to => flavors}).and_return("chocolate")
      expect(shell.ask('What\'s your favorite Neopolitan flavor?', :limited_to => flavors)).to eq("chocolate")
    end

    it "prints a message to the user with the available options, expects case-sensitive matching, and reasks the question after an incorrect response" do
      flavors = %w(strawberry chocolate vanilla)
      expect($stdout).to receive(:print).with("Your response must be one of: [strawberry, chocolate, vanilla]. Please try again.\n")
      expect(Thor::LineEditor).to receive(:readline).with('What\'s your favorite Neopolitan flavor? [strawberry, chocolate, vanilla] ', {:limited_to => flavors}).and_return("moose tracks", "chocolate")
      expect(shell.ask('What\'s your favorite Neopolitan flavor?', :limited_to => flavors)).to eq("chocolate")
    end

    it "prints a message to the user with the available options, expects case-sensitive matching, and reasks the question after a case-insensitive match" do
      flavors = %w(strawberry chocolate vanilla)
      expect($stdout).to receive(:print).with("Your response must be one of: [strawberry, chocolate, vanilla]. Please try again.\n")
      expect(Thor::LineEditor).to receive(:readline).with('What\'s your favorite Neopolitan flavor? [strawberry, chocolate, vanilla] ', {:limited_to => flavors}).and_return("cHoCoLaTe", "chocolate")
      expect(shell.ask('What\'s your favorite Neopolitan flavor?', :limited_to => flavors)).to eq("chocolate")
    end

    it "prints a message to the user with the available options, expects case-insensitive matching, and determines the correctness of the answer" do
      flavors = %w(strawberry chocolate vanilla)
      expect(Thor::LineEditor).to receive(:readline).with('What\'s your favorite Neopolitan flavor? [strawberry, chocolate, vanilla] ', {:limited_to => flavors, :case_insensitive => true}).and_return("CHOCOLATE")
      expect(shell.ask('What\'s your favorite Neopolitan flavor?', :limited_to => flavors, :case_insensitive => true)).to eq("chocolate")
    end

    it "prints a message to the user with the available options, expects case-insensitive matching, and reasks the question after an incorrect response" do
      flavors = %w(strawberry chocolate vanilla)
      expect($stdout).to receive(:print).with("Your response must be one of: [strawberry, chocolate, vanilla]. Please try again.\n")
      expect(Thor::LineEditor).to receive(:readline).with('What\'s your favorite Neopolitan flavor? [strawberry, chocolate, vanilla] ', {:limited_to => flavors, :case_insensitive => true}).and_return("moose tracks", "chocolate")
      expect(shell.ask('What\'s your favorite Neopolitan flavor?', :limited_to => flavors, :case_insensitive => true)).to eq("chocolate")
    end

    it "prints a message to the user containing a default and sets the default if only enter is pressed" do
      expect(Thor::LineEditor).to receive(:readline).with('What\'s your favorite Neopolitan flavor? (vanilla) ', {:default => "vanilla"}).and_return("")
      expect(shell.ask('What\'s your favorite Neopolitan flavor?', :default => "vanilla")).to eq("vanilla")
    end

    it "prints a message to the user with the available options and reasks the question after an incorrect response and then returns the default" do
      flavors = %w(strawberry chocolate vanilla)
      expect($stdout).to receive(:print).with("Your response must be one of: [strawberry, chocolate, vanilla]. Please try again.\n")
      expect(Thor::LineEditor).to receive(:readline).with('What\'s your favorite Neopolitan flavor? [strawberry, chocolate, vanilla] (vanilla) ', {:default => "vanilla", :limited_to => flavors}).and_return("moose tracks", "")
      expect(shell.ask("What's your favorite Neopolitan flavor?", :default => "vanilla", :limited_to => flavors)).to eq("vanilla")
    end
  end

  describe "#yes?" do
    it "asks the user and returns true if the user replies yes" do
      expect(Thor::LineEditor).to receive(:readline).with("Should I overwrite it? ", {:add_to_history => false}).and_return("y")
      expect(shell.yes?("Should I overwrite it?")).to be true
    end

    it "asks the user and returns false if the user replies no" do
      expect(Thor::LineEditor).to receive(:readline).with("Should I overwrite it? ", {:add_to_history => false}).and_return("n")
      expect(shell.yes?("Should I overwrite it?")).not_to be true
    end

    it "asks the user and returns false if the user replies with an answer other than yes or no" do
      expect(Thor::LineEditor).to receive(:readline).with("Should I overwrite it? ", {:add_to_history => false}).and_return("foobar")
      expect(shell.yes?("Should I overwrite it?")).to be false
    end
  end

  describe "#no?" do
    it "asks the user and returns true if the user replies no" do
      expect(Thor::LineEditor).to receive(:readline).with("Should I overwrite it? ", {:add_to_history => false}).and_return("n")
      expect(shell.no?("Should I overwrite it?")).to be true
    end

    it "asks the user and returns false if the user replies yes" do
      expect(Thor::LineEditor).to receive(:readline).with("Should I overwrite it? ", {:add_to_history => false}).and_return("Yes")
      expect(shell.no?("Should I overwrite it?")).to be false
    end

    it "asks the user and returns false if the user replies with an answer other than yes or no" do
      expect(Thor::LineEditor).to receive(:readline).with("Should I overwrite it? ", {:add_to_history => false}).and_return("foobar")
      expect(shell.no?("Should I overwrite it?")).to be false
    end
  end

  describe "#say" do
    it "prints a message to the user" do
      expect($stdout).to receive(:print).with("Running...\n")
      shell.say("Running...")
    end

    it "prints a message to the user without new line if it ends with a whitespace" do
      expect($stdout).to receive(:print).with("Running... ")
      shell.say("Running... ")
    end

    it "does not use a new line with whitespace+newline embedded" do
      expect($stdout).to receive(:print).with("It's \nRunning...\n")
      shell.say("It's \nRunning...")
    end

    it "prints a message to the user without new line" do
      expect($stdout).to receive(:print).with("Running...")
      shell.say("Running...", nil, false)
    end

    it "coerces everything to a string before printing" do
      expect($stdout).to receive(:print).with("this_is_not_a_string\n")
      shell.say(:this_is_not_a_string, nil, true)
    end

    it "does not print a message if muted" do
      expect($stdout).not_to receive(:print)
      shell.mute do
        shell.say("Running...")
      end
    end

    it "does not print a message if base is set to quiet" do
      shell.base = MyCounter.new [1, 2]
      expect(shell.base).to receive(:options).and_return(:quiet => true)

      expect($stdout).not_to receive(:print)
      shell.say("Running...")
    end
  end

  describe "#say_error" do
    it "prints a message to the user" do
      expect($stderr).to receive(:print).with("Running...\n")
      shell.say_error("Running...")
    end

    it "prints a message to the user without new line if it ends with a whitespace" do
      expect($stderr).to receive(:print).with("Running... ")
      shell.say_error("Running... ")
    end

    it "does not use a new line with whitespace+newline embedded" do
      expect($stderr).to receive(:print).with("It's \nRunning...\n")
      shell.say_error("It's \nRunning...")
    end

    it "prints a message to the user without new line" do
      expect($stderr).to receive(:print).with("Running...")
      shell.say_error("Running...", nil, false)
    end

    it "coerces everything to a string before printing" do
      expect($stderr).to receive(:print).with("this_is_not_a_string\n")
      shell.say_error(:this_is_not_a_string, nil, true)
    end

    it "does not print a message if muted" do
      expect($stderr).not_to receive(:print)
      shell.mute do
        shell.say_error("Running...")
      end
    end

    it "does not print a message if base is set to quiet" do
      shell.base = MyCounter.new [1, 2]
      expect(shell.base).to receive(:options).and_return(:quiet => true)

      expect($stderr).not_to receive(:print)
      shell.say_error("Running...")
    end
  end

  describe "#print_wrapped" do
    let(:message) do
      "Creates a back-up of the given folder by compressing it in a .tar.gz\n"\
      "file and then uploading it to the configured Amazon S3 Bucket.\n\n"\
      "It does not verify the integrity of the generated back-up."
    end

    before do
      allow(ENV).to receive(:[]).with("THOR_COLUMNS").and_return(80)
    end

    context "without indentation" do
      subject(:wrap_text) { described_class.new.print_wrapped(message) }

      let(:expected_output) do
        "Creates a back-up of the given folder by compressing it in a .tar.gz file and\n"\
        "then uploading it to the configured Amazon S3 Bucket.\n\n"\
        "It does not verify the integrity of the generated back-up.\n"
      end

      it "properly wraps the text around the 80th column" do
        expect { wrap_text }.to output(expected_output).to_stdout
      end
    end

    context "with indentation" do
      subject(:wrap_text) { described_class.new.print_wrapped(message, :indent => 4) }

      let(:expected_output) do
        "    Creates a back-up of the given folder by compressing it in a .tar.gz file\n"\
        "    and then uploading it to the configured Amazon S3 Bucket.\n\n"\
        "    It does not verify the integrity of the generated back-up.\n"
      end

      it "properly wraps the text around the 80th column" do
        expect { wrap_text }.to output(expected_output).to_stdout
      end
    end
  end

  describe "#say_status" do
    it "prints a message to the user with status" do
      expect($stdout).to receive(:print).with("      create  ~/.thor/command.thor\n")
      shell.say_status(:create, "~/.thor/command.thor")
    end

    it "always uses new line" do
      expect($stdout).to receive(:print).with("      create  \n")
      shell.say_status(:create, "")
    end

    it "indents a multiline message" do
      status = :foobar
      lines = ["first line", "second line", "  third line", "    fourth line"]

      expect($stdout).to receive(:print) do |string|
        formatted_status = string[/^\s*#{status}\s*/]
        margin = " " * formatted_status.length

        expect(string).to eq(formatted_status + lines.join("\n#{margin}") + "\n")
      end

      shell.say_status(status, lines.join("\n") + "\n")
    end

    it "does not print a message if base is muted" do
      expect(shell).to receive(:mute?).and_return(true)
      expect($stdout).not_to receive(:print)

      shell.mute do
        shell.say_status(:created, "~/.thor/command.thor")
      end
    end

    it "does not print a message if base is set to quiet" do
      base = MyCounter.new [1, 2]
      expect(base).to receive(:options).and_return(:quiet => true)

      expect($stdout).not_to receive(:print)
      shell.base = base
      shell.say_status(:created, "~/.thor/command.thor")
    end

    it "does not print a message if log status is set to false" do
      expect($stdout).not_to receive(:print)
      shell.say_status(:created, "~/.thor/command.thor", false)
    end

    it "uses padding to set message's left margin" do
      shell.padding = 2
      expect($stdout).to receive(:print).with("      create      ~/.thor/command.thor\n")
      shell.say_status(:create, "~/.thor/command.thor")
    end
  end

  describe "#print_in_columns" do
    before do
      @array = [1_234_567_890]
      @array += ("a".."e").to_a
    end

    it "prints in columns" do
      content = capture(:stdout) { shell.print_in_columns(@array) }
      expect(content.rstrip).to eq("1234567890  a           b           c           d           e")
    end
  end

  describe "#print_table" do
    before do
      @table = []
      @table << ["abc", "#123", "first three"]
      @table << ["", "#0", "empty"]
      @table << ["xyz", "#786", "last three"]
    end

    it "prints a table" do
      content = capture(:stdout) { shell.print_table(@table) }
      expect(content).to eq(<<-TABLE)
abc  #123  first three
     #0    empty
xyz  #786  last three
TABLE
    end

    it "prints a table with indentation" do
      content = capture(:stdout) { shell.print_table(@table, :indent => 2) }
      expect(content).to eq(<<-TABLE)
  abc  #123  first three
       #0    empty
  xyz  #786  last three
TABLE
    end

    it "uses maximum terminal width" do
      @table << ["def", "#456", "Lançam foo bar"]
      @table << ["ghi", "#789", "بالله  عليكم"]
      expect(shell).to receive(:terminal_width).and_return(20)
      content = capture(:stdout) { shell.print_table(@table, :indent => 2, :truncate => true) }
      expect(content).to eq(<<-TABLE)
  abc  #123  firs...
       #0    empty
  xyz  #786  last...
  def  #456  Lanç...
  ghi  #789  بالل...
TABLE
    end

    it "honors the colwidth option" do
      content = capture(:stdout) { shell.print_table(@table, :colwidth => 10) }
      expect(content).to eq(<<-TABLE)
abc         #123  first three
            #0    empty
xyz         #786  last three
TABLE
    end

    it "prints tables with implicit columns" do
      2.times { @table.first.pop }
      content = capture(:stdout) { shell.print_table(@table) }
      expect(content).to eq(<<-TABLE)
abc#{"  "}
     #0    empty
xyz  #786  last three
TABLE
    end

    it "prints a table with small numbers and right-aligns them" do
      table = [
        ["Name", "Number", "Color"], # rubocop: disable WordArray
        ["Erik", 1, "green"]
      ]
      content = capture(:stdout) { shell.print_table(table) }
      expect(content).to eq(<<-TABLE)
Name  Number  Color
Erik       1  green
TABLE
    end

    it "doesn't output extra spaces for right-aligned columns in the last column" do
      table = [
        ["Name", "Number"], # rubocop: disable WordArray
        ["Erik", 1]
      ]
      content = capture(:stdout) { shell.print_table(table) }
      expect(content).to eq(<<-TABLE)
Name  Number
Erik       1
TABLE
    end

    it "prints a table with big numbers" do
      table = [
        ["Name", "Number", "Color"], # rubocop: disable WordArray
        ["Erik", 1_234_567_890_123, "green"]
      ]
      content = capture(:stdout) { shell.print_table(table) }
      expect(content).to eq(<<-TABLE)
Name  Number         Color
Erik  1234567890123  green
      TABLE
    end
  end

  describe "#file_collision" do
    it "shows a menu with options" do
      expect(Thor::LineEditor).to receive(:readline).with('Overwrite foo? (enter "h" for help) [Ynaqh] ', {:add_to_history => false}).and_return("n")
      shell.file_collision("foo")
    end

    it "outputs a new line and returns true if stdin is closed" do
      expect($stdout).to receive(:print).with("\n")
      expect(Thor::LineEditor).to receive(:readline).and_return(nil)
      expect(shell.file_collision("foo")).to be true
    end

    it "returns true if the user chooses default option" do
      expect(Thor::LineEditor).to receive(:readline).and_return("")
      expect(shell.file_collision("foo")).to be true
    end

    it "returns false if the user chooses no" do
      expect(Thor::LineEditor).to receive(:readline).and_return("n")
      expect(shell.file_collision("foo")).to be false
    end

    it "returns true if the user chooses yes" do
      expect(Thor::LineEditor).to receive(:readline).and_return("y")
      expect(shell.file_collision("foo")).to be true
    end

    it "shows help usage if the user chooses help" do
      expect(Thor::LineEditor).to receive(:readline).and_return("h", "n")
      help = capture(:stdout) { shell.file_collision("foo") }
      expect(help).to match(/h \- help, show this help/)
    end

    it "quits if the user chooses quit" do
      expect($stdout).to receive(:print).with("Aborting...\n")
      expect(Thor::LineEditor).to receive(:readline).and_return("q")

      expect do
        shell.file_collision("foo")
      end.to raise_error(SystemExit)
    end

    it "always returns true if the user chooses always" do
      expect(Thor::LineEditor).to receive(:readline).with('Overwrite foo? (enter "h" for help) [Ynaqh] ', {:add_to_history => false}).and_return("a")

      expect(shell.file_collision("foo")).to be true

      expect($stdout).not_to receive(:print)
      expect(shell.file_collision("foo")).to be true
    end

    describe "when a block is given" do
      it "displays diff and merge options to the user" do
        expect(Thor::LineEditor).to receive(:readline).with('Overwrite foo? (enter "h" for help) [Ynaqdhm] ', {:add_to_history => false}).and_return("s")
        shell.file_collision("foo") {}
      end

      it "invokes the diff command" do
        expect(Thor::LineEditor).to receive(:readline).and_return("d")
        expect(Thor::LineEditor).to receive(:readline).and_return("n")
        expect(shell).to receive(:system).with(/diff -u/)
        capture(:stdout) { shell.file_collision("foo") {} }
      end

      it "invokes the merge tool" do
        allow(shell).to receive(:merge_tool).and_return("meld")
        expect(Thor::LineEditor).to receive(:readline).and_return("m")
        expect(shell).to receive(:system).with(/meld/)
        capture(:stdout) { shell.file_collision("foo") {} }
      end

      it "invokes the merge tool that specified at ENV['THOR_MERGE']" do
        allow(ENV).to receive(:[]).with("THOR_MERGE").and_return("meld")
        expect(Thor::LineEditor).to receive(:readline).and_return("m")
        expect(shell).to receive(:system).with(/meld/)
        capture(:stdout) { shell.file_collision("foo") {} }
      end

      it "show warning if user chooses merge but merge tool is not specified" do
        allow(shell).to receive(:merge_tool).and_return("")
        expect(Thor::LineEditor).to receive(:readline).and_return("m")
        expect(Thor::LineEditor).to receive(:readline).and_return("n")
        help = capture(:stdout) { shell.file_collision("foo") {} }
        expect(help).to match(/Please specify merge tool to `THOR_MERGE` env/)
      end
    end
  end
end
