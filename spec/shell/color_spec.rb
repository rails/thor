require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Thor::Shell::Color do
  def shell
    @shell ||= Thor::Shell::Color.new
  end

  describe "#say" do
    it "set the color if specified" do
      mock($stdout).puts("\e[32mWow! Now we have colors!\e[0m")
      shell.say "Wow! Now we have colors!", :green
    end

    it "does not use a new line even with colors" do
      mock($stdout).print("\e[32mWow! Now we have colors! \e[0m")
      shell.say "Wow! Now we have colors! ", :green
    end
  end

  describe "#say_status" do
    it "uses color to say status" do
      mock($stdout).puts("\e[1m\e[31m    conflict\e[0m  README")
      shell.say_status :conflict, "README", :red
    end
  end

  describe "#file_collision" do
    describe "when a block is given" do
      it "invokes the diff command" do
        stub($stdout).print
        mock($stdin).gets{ 'd' }
        mock($stdin).gets{ 'n' }

        output = capture(:stdout){ shell.file_collision('spec/fixtures/doc/README'){ "README\nEND\n" } }
        output.must =~ /\e\[31m\- __start__\e\[0m/
        output.must =~ /^  README/
        output.must =~ /\e\[32m\+ END\e\[0m/
      end
    end
  end
end
