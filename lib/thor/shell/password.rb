require 'tempfile'

class Thor
  module Shell
    module Password
      if RUBY_PLATFORM =~ /mswin32|mingw32/

        def ask_passwordly(statement, color = nil)
          say("#{statement} ", color)

          require "Win32API"
          char = nil
          password = ''

          while char = Win32API.new("crtdll", "_getch", [ ], "L").Call do
            break if char == 10 || char == 13 # received carriage return or newline
            if char == 127 || char == 8 # backspace and delete
              password.slice!(-1, 1)
            else
              # windows might throw a -1 at us so make sure to handle RangeError
              (password << char.chr) rescue RangeError
            end
          end
          puts
          return password
        end

      else

        def ask_passwordly(statement, color = nil)
          system "stty -echo"
          password = ask(statement, color)
          puts
          return password
        ensure
          system "stty echo"
        end
      end
    end
  end
end