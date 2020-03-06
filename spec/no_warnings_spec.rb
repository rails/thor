require "open3"

context "when $VERBOSE is enabled" do
  it "prints no warnings" do
    root = File.expand_path("..", __dir__)
    _, err, = Open3.capture3("ruby -I #{root}/lib #{root}/spec/fixtures/verbose.thor")

    expect(err).to be_empty
  end

  it "prints no warnings even when erroring" do
    root = File.expand_path("..", __dir__)
    _, err, = Open3.capture3("ruby -I #{root}/lib #{root}/spec/fixtures/verbose.thor noop")
    expect(err).to_not match(/warning:/)
  end
end
