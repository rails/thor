require "helper"

describe Thor do
  def shell
    @shell ||= Thor::Base.shell.new
  end

  describe "#sort - default" do
    my_script = Class.new(Thor) do
      desc "a", "First Command"
      def a; end

      desc "z", "Last Command"
      def z; end
    end

    before do
      @content = capture(:stdout) { my_script.help(shell) }
    end

    it "sorts them lexicographillay" do
      expect(@content).to match(/:a.+:help.+:z/m)
    end
  end


  describe "#sort - simple override" do
    my_script = Class.new(Thor) do
      desc "a", "First Command"
      def a; end

      desc "z", "Last Command"
      def z; end

      def self.sort_commands!(list)
        list.sort!
        list.reverse!
      end

    end

    before do
      @content = capture(:stdout) { my_script.help(shell) }
    end

    it "sorts them in reverse" do
      expect(@content).to match(/:z.+:help.+:a/m)
    end
  end


  describe "#sort - simple override" do
    my_script = Class.new(Thor) do
      desc "a", "First Command"
      def a; end

      desc "z", "Last Command"
      def z; end

      def self.sort_commands!(list)
        list.sort_by! do |a,b|
          a[0] == :help ? -1 : a[0] <=> b[0]
        end
      end
    end

    before do
      @content = capture(:stdout) { my_script.help(shell) }
    end

    it "puts help first then sorts them lexicographillay" do
      expect(@content).to match(/:help.+:a.+:z/m)
    end
  end
end