class Thor
  module Shell
    class Basic
      # Ask something to the user and receives a response.
      #
      # ==== Example
      # ask("What is your name?")
      #
      def ask(statement)
        say("#{statement} ")
        $stdin.gets.strip
      end

      # Say (print) something to the user. If the sentence ends with a whitespace
      # or tab character, a new line is not appended (print + flush). Otherwise
      # are passed straight to puts (behavior got from Highline).
      #
      # ==== Example
      # say("I know you knew that.")
      #
      def say(statement='')
        statement = statement.to_s

        if statement[-1, 1] == ' ' || statement[-1, 1] == "\t"
          $stdout.print(statement)
          $stdout.flush
        else
          $stdout.puts(statement)
        end
      end

      # Make a question the to user and returns true if the user replies "y" or
      # "yes".
      #
      def yes?(statement)
        ["y", "yes"].include?(ask(statement).downcase)
      end

      # Make a question the to user and returns true if the user replies "n" or
      # "no".
      #
      def no?(statement)
        !yes?(statement)
      end

      # Prints a table.
      #
      # ==== Parameters
      # Array[Array[String, String, ...]]
      #
      def table(table, options={})
        return if table.empty?

        formats = []
        0.upto(table.first.length - 2) do |i|
          maxima = table.max{ |a,b| a[i].size <=> b[i].size }[i].size
          formats << "%-#{maxima + 2}s"
        end

        formats[0] = formats[0].insert(0, " " * options[:ident]) if options[:ident]
        formats << "%s"

        if options[:emphasize_last]
          table.each do |row|
            next if row[-1].empty?
            row[-1] = "# #{row[-1]}"
          end
        end

        table.each do |row|
          row.each_with_index do |column, i|
            $stdout.print formats[i] % column.to_s
          end
          $stdout.puts
        end
      end
    end
  end
end
