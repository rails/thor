describe "The library itself" do
  def check_for_spec_defs_with_single_quotes(filename)
    failing_lines = []

    File.readlines(filename).each_with_index do |line, number|
      failing_lines << number + 1 if line =~ /^ *(describe|it|context) {1}'{1}/
    end

    "#{filename} uses inconsistent single quotes on lines #{failing_lines.join(', ')}" unless failing_lines.empty?
  end

  def check_for_tab_characters(filename)
    failing_lines = []
    File.readlines(filename).each_with_index do |line, number|
      failing_lines << number + 1 if line =~ /\t/
    end

    "#{filename} has tab characters on lines #{failing_lines.join(', ')}" unless failing_lines.empty?
  end

  def check_for_extra_spaces(filename)
    failing_lines = []
    File.readlines(filename).each_with_index do |line, number|
      next if line =~ /^\s+#.*\s+\n$/
      failing_lines << number + 1 if line =~ /\s+\n$/
    end

    "#{filename} has spaces on the EOL on lines #{failing_lines.join(', ')}" unless failing_lines.empty?
  end

  RSpec::Matchers.define :be_well_formed do
    failure_message do |actual|
      actual.join("\n")
    end

    match(&:empty?)
  end

  it "has no malformed whitespace" do
    exempt = /\.gitmodules|\.marshal|fixtures|vendor|spec|ssl_certs|LICENSE/
    error_messages = []
    Dir.chdir(File.expand_path("../..", __FILE__)) do
      `git ls-files`.split("\n").each do |filename|
        next if filename =~ exempt
        error_messages << check_for_tab_characters(filename)
        error_messages << check_for_extra_spaces(filename)
      end
    end
    expect(error_messages.compact).to be_well_formed
  end

  it "uses double-quotes consistently in specs" do
    included = /spec/
    error_messages = []
    Dir.chdir(File.expand_path("../", __FILE__)) do
      `git ls-files`.split("\n").each do |filename|
        next unless filename =~ included
        error_messages << check_for_spec_defs_with_single_quotes(filename)
      end
    end
    expect(error_messages.compact).to be_well_formed
  end
end
