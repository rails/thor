require "helper"

describe Thor::Shell::Color do
  def shell
    @shell ||= Thor::Shell::Color.new
  end

  before do
    allow($stdout).to receive(:tty?).and_return(true)
    allow(ENV).to receive(:[]).and_return(nil)
    allow(ENV).to receive(:[]).with("TERM").and_return("ansi")
    allow_any_instance_of(StringIO).to receive(:tty?).and_return(true)
  end

  describe "#ask" do
    it "sets the color if specified and tty?" do
      expect(Thor::LineEditor).to receive(:readline).with("\e[32mIs this green? \e[0m", anything).and_return("yes")
      shell.ask "Is this green?", :green

      expect(Thor::LineEditor).to receive(:readline).with("\e[32mIs this green? [Yes, No, Maybe] \e[0m", anything).and_return("Yes")
      shell.ask "Is this green?", :green, :limited_to => %w(Yes No Maybe)
    end

    it "does not set the color if specified and NO_COLOR is set" do
      allow(ENV).to receive(:[]).with("NO_COLOR").and_return("")
      expect(Thor::LineEditor).to receive(:readline).with("Is this green? ", anything).and_return("yes")
      shell.ask "Is this green?", :green

      expect(Thor::LineEditor).to receive(:readline).with("Is this green? [Yes, No, Maybe] ", anything).and_return("Yes")
      shell.ask "Is this green?", :green, :limited_to => %w(Yes No Maybe)
    end

    it "handles an Array of colors" do
      expect(Thor::LineEditor).to receive(:readline).with("\e[32m\e[47m\e[1mIs this green on white? \e[0m", anything).and_return("yes")
      shell.ask "Is this green on white?", [:green, :on_white, :bold]
    end

    it "supports the legacy color syntax" do
      expect(Thor::LineEditor).to receive(:readline).with("\e[1m\e[34mIs this legacy blue? \e[0m", anything).and_return("yes")
      shell.ask "Is this legacy blue?", [:blue, true]
    end
  end

  describe "#say" do
    it "set the color if specified and tty?" do
      out = capture(:stdout) do
        shell.say "Wow! Now we have colors!", :green
      end

      expect(out.chomp).to eq("\e[32mWow! Now we have colors!\e[0m")
    end

    it "does not set the color if output is not a tty" do
      out = capture(:stdout) do
        expect($stdout).to receive(:tty?).and_return(false)
        shell.say "Wow! Now we have colors!", :green
      end

      expect(out.chomp).to eq("Wow! Now we have colors!")
    end

    it "does not set the color if NO_COLOR is set" do
      allow(ENV).to receive(:[]).with("NO_COLOR").and_return("")
      out = capture(:stdout) do
        shell.say "Wow! Now we have colors!", :green
      end

      expect(out.chomp).to eq("Wow! Now we have colors!")
    end

    it "does not use a new line even with colors" do
      out = capture(:stdout) do
        shell.say "Wow! Now we have colors! ", :green
      end

      expect(out.chomp).to eq("\e[32mWow! Now we have colors! \e[0m")
    end

    it "handles an Array of colors" do
      out = capture(:stdout) do
        shell.say "Wow! Now we have colors *and* background colors", [:green, :on_red, :bold]
      end

      expect(out.chomp).to eq("\e[32m\e[41m\e[1mWow! Now we have colors *and* background colors\e[0m")
    end

    it "supports the legacy color syntax" do
      out = capture(:stdout) do
        shell.say "Wow! This still works?", [:blue, true]
      end

      expect(out.chomp).to eq("\e[1m\e[34mWow! This still works?\e[0m")
    end
  end

  describe "#say_status" do
    it "uses color to say status" do
      out = capture(:stdout) do
        shell.say_status :conflict, "README", :red
      end

      expect(out.chomp).to eq("\e[1m\e[31m    conflict\e[0m  README")
    end
  end

  describe "#set_color" do
    it "colors a string with a foreground color" do
      red = shell.set_color "hi!", :red
      expect(red).to eq("\e[31mhi!\e[0m")
    end

    it "colors a string with a background color" do
      on_red = shell.set_color "hi!", :white, :on_red
      expect(on_red).to eq("\e[37m\e[41mhi!\e[0m")
    end

    it "colors a string with a bold color" do
      bold = shell.set_color "hi!", :white, true
      expect(bold).to eq("\e[1m\e[37mhi!\e[0m")

      bold = shell.set_color "hi!", :white, :bold
      expect(bold).to eq("\e[37m\e[1mhi!\e[0m")

      bold = shell.set_color "hi!", :white, :on_red, :bold
      expect(bold).to eq("\e[37m\e[41m\e[1mhi!\e[0m")
    end

    it "does nothing when there are no colors" do
      colorless = shell.set_color "hi!", nil
      expect(colorless).to eq("hi!")

      colorless = shell.set_color "hi!"
      expect(colorless).to eq("hi!")
    end

    it "does nothing when stdout is not a tty" do
      allow($stdout).to receive(:tty?).and_return(false)
      colorless = shell.set_color "hi!", :white
      expect(colorless).to eq("hi!")
    end

    it "does nothing when the TERM environment variable is set to 'dumb'" do
      allow(ENV).to receive(:[]).with("TERM").and_return("dumb")
      colorless = shell.set_color "hi!", :white
      expect(colorless).to eq("hi!")
    end

    it "does nothing when the NO_COLOR environment variable is set" do
      allow(ENV).to receive(:[]).with("NO_COLOR").and_return("")
      allow($stdout).to receive(:tty?).and_return(true)
      colorless = shell.set_color "hi!", :white
      expect(colorless).to eq("hi!")
    end
  end

  describe "#file_collision" do
    describe "when a block is given" do
      it "invokes the diff command" do
        allow($stdout).to receive(:print)
        allow($stdout).to receive(:tty?).and_return(true)
        expect(Thor::LineEditor).to receive(:readline).and_return("d", "n")

        output = capture(:stdout) { shell.file_collision("spec/fixtures/doc/README") { "README\nEND\n" } }
        expect(output).to match(/\e\[31m\- __start__\e\[0m/)
        expect(output).to match(/^  README/)
        expect(output).to match(/\e\[32m\+ END\e\[0m/)
      end
    end
  end
end
