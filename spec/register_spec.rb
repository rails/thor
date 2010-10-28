require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

class BoringVendorProvidedCLI < Thor
  desc "boring", "do boring stuff"
  def boring
    puts "bored. <yawn>"
  end
end

class ExcitingPluginCLI < Thor
  desc "hooray", "say hooray!"
  def hooray
    puts "hooray!"
  end

  desc "fireworks", "exciting fireworks!"
  def fireworks
    puts "kaboom!"
  end
end

class SuperSecretPlugin < Thor
  default_task :squirrel

  desc "squirrel", "All of secret squirrel's secrets"
  def squirrel
    puts "I love nuts"
  end
end

# TODO:
# * register a Thor::Group should cause it to be invoked


BoringVendorProvidedCLI.register(
  ExcitingPluginCLI,
  "exciting",
  "do exciting things",
  "Various non-boring actions")

BoringVendorProvidedCLI.register(
  SuperSecretPlugin,
  "secret",
  "secret stuff",
  "Nothing to see here. Move along.",
  :hide => true)

describe ".register-ing a Thor subclass" do
  it "registers the plugin as a subcommand" do
    fireworks_output = capture(:stdout) { BoringVendorProvidedCLI.start(%w[exciting fireworks]) }
    fireworks_output.must == "kaboom!\n"
  end

  it "includes the plugin's usage in the help" do
    help_output = capture(:stdout) { BoringVendorProvidedCLI.start(%w[help]) }
    help_output.must include('do exciting things')
  end

  context "when hidden" do
    it "omits the hidden plugin's usage from the help" do
      help_output = capture(:stdout) { BoringVendorProvidedCLI.start(%w[help]) }
      help_output.must_not include('secret stuff')
    end

    it "registers the plugin as a subcommand" do
      secret_output = capture(:stdout) { BoringVendorProvidedCLI.start(%w[secret squirrel]) }
      secret_output.must == "I love nuts\n"
    end
  end
end
