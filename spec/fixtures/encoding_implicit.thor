# frozen_string_literal: true

class EncodingImplicit < Thor
  SOME_STRING = "Some λέξεις 一些词 🎉"

  desc "encoding", "tests that encoding is correct"

  def encoding
    puts "#{SOME_STRING.inspect}: #{SOME_STRING.encoding}:"
    if SOME_STRING.encoding.name == "UTF-8"
      puts "ok"
    else
      puts "expected #{SOME_STRING.encoding.name} to equal UTF-8"
    end
  end
end
