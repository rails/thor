class Thor
  module LineEditor
    def self.readline(prompt)
      $stdout.print(prompt)
      $stdin.gets
    end
  end
end
