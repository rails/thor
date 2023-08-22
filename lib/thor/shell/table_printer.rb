require_relative "column_printer"
require_relative "terminal"

class Thor
  module Shell
    class TablePrinter < ColumnPrinter
      def initialize(stdout, options = {})
        super
        @formats = []
        @maximas = []
        @colwidth = options[:colwidth]
        @truncate = options[:truncate] == true ? Terminal.terminal_width : options[:truncate]
      end

      def print(array)
        return if array.empty?

        prepare(array)

        array.each do |row|
          sentence = "".dup

          row.each_with_index do |column, index|
            maxima = @maximas[index]

            f = if column.is_a?(Numeric)
              if index == row.size - 1
                # Don't output 2 trailing spaces when printing the last column
                "%#{maxima}s"
              else
                "%#{maxima}s  "
              end
            else
              @formats[index]
            end
            sentence << f % column.to_s
          end

          sentence = truncate(sentence)
          stdout.puts sentence
        end
      end

    private

      def prepare(array)
        @formats << "%-#{@colwidth + 2}s".dup if @colwidth
        start = @colwidth ? 1 : 0

        colcount = array.max { |a, b| a.size <=> b.size }.size

        start.upto(colcount - 1) do |index|
          maxima = array.map { |row| row[index] ? row[index].to_s.size : 0 }.max
          @maximas << maxima
          @formats << if index == colcount - 1
            # Don't output 2 trailing spaces when printing the last column
            "%-s".dup
          else
            "%-#{maxima + 2}s".dup
          end
        end

        @formats[0] = @formats[0].insert(0, " " * @indent)
        @formats << "%s"
      end

      def truncate(string)
        return string unless @truncate
        as_unicode do
          chars = string.chars.to_a
          if chars.length <= @truncate
            chars.join
          else
            chars[0, @truncate - 3].join + "..."
          end
        end
      end

      if "".respond_to?(:encode)
        def as_unicode
          yield
        end
      else
        def as_unicode
          old = $KCODE # rubocop:disable Style/GlobalVars
          $KCODE = "U" # rubocop:disable Style/GlobalVars
          yield
        ensure
          $KCODE = old # rubocop:disable Style/GlobalVars
        end
      end
    end
  end
end

