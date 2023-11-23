# encoding: ISO-8859-7
# frozen_string_literal: true

class EncodingOther < Thor
  SOME_STRING = "Some λέξεις"

  desc "encoding", "tests that encoding is correct"

  def encoding
    puts "#{SOME_STRING.inspect}: #{SOME_STRING.encoding}:"
    if SOME_STRING.encoding.name == "ISO-8859-7"
      puts "ok"
    else
      puts "expected #{SOME_STRING.encoding.name} to equal ISO-8859-7"
    end
  end
end
