require "helper"

describe Thor2 do
  describe "#check_unknown_options!" do
    it "still accept options and arguments" do
      stdout, _, status = run_thor_fixture_standalone('thor2', %w(checked command --verbose))

      expect(stdout.strip).to eq [{"verbose" => true}, %w[command]].inspect
      expect(status.exitstatus).to eq(0)
    end

    it "does not accept if non-option that looks like an option is after an argument and exits with code 1" do
      _stdout, stderr, status = run_thor_fixture_standalone('thor2', %w(checked command --foo --bar))
      expect(stderr.strip).to eq("Unknown switches '--foo, --bar'")
      expect(status.exitstatus).to eq(1)
    end
  end if RUBY_VERSION > "1.8.7"

  it "checks the default type" do
    expect do
      Class.new(Thor2) do
        option "bar", :type => :numeric, :default => "foo"
      end
    end.to raise_error(ArgumentError, "Expected numeric default value for '--bar'; got \"foo\" (string)")
  end
end
