require 'thor/shell/basic'

class Thor
  module Shell
    # Inherit from Thor::Shell::Basic and add set_color behavior. Check
    # Thor::Shell::Basic to see all available methods.
    #
    class HTML < Basic
      include DiffLines

      # The start of an HTML bold sequence.
      BOLD       = "font-weight: bold"

      # Set the terminal's foreground HTML color to black.
      BLACK      = 'color: black'
      # Set the terminal's foreground HTML color to red.
      RED        = 'color: red'
      # Set the terminal's foreground HTML color to green.
      GREEN      = 'color: green'
      # Set the terminal's foreground HTML color to yellow.
      YELLOW     = 'color: yellow'
      # Set the terminal's foreground HTML color to blue.
      BLUE       = 'color: blue'
      # Set the terminal's foreground HTML color to magenta.
      MAGENTA    = 'color: magenta'
      # Set the terminal's foreground HTML color to cyan.
      CYAN       = 'color: cyan'
      # Set the terminal's foreground HTML color to white.
      WHITE      = 'color: white'

      # Set the terminal's background HTML color to black.
      ON_BLACK   = 'background-color: black'
      # Set the terminal's background HTML color to red.
      ON_RED     = 'background-color: red'
      # Set the terminal's background HTML color to green.
      ON_GREEN   = 'background-color: green'
      # Set the terminal's background HTML color to yellow.
      ON_YELLOW  = 'background-color: yellow'
      # Set the terminal's background HTML color to blue.
      ON_BLUE    = 'background-color: blue'
      # Set the terminal's background HTML color to magenta.
      ON_MAGENTA = 'background-color: magenta'
      # Set the terminal's background HTML color to cyan.
      ON_CYAN    = 'background-color: cyan'
      # Set the terminal's background HTML color to white.
      ON_WHITE   = 'background-color: white'

      # Set color by using a string or one of the defined constants. If a third
      # option is set to true, it also adds bold to the string. This is based
      # on Highline implementation and it automatically appends CLEAR to the end
      # of the returned String.
      #
      def set_color(string, *colors)
        if colors.all? { |color| color.is_a?(Symbol) || color.is_a?(String) }
          html_colors = colors.map { |color| lookup_color(color) }
          "<span style=\"#{html_colors.join("; ")};\">#{string}</span>"
        else
          color, bold = colors
          html_color = self.class.const_get(color.to_s.upcase) if color.is_a?(Symbol)
          styles = [html_color]
          styles << BOLD if bold
          "<span style=\"#{styles.join("; ")};\">#{string}</span>"
        end
      end

      # Ask something to the user and receives a response.
      #
      # ==== Example
      # ask("What is your name?")
      #
      # TODO: Implement #ask for Thor::Shell::HTML
      def ask(statement, color=nil)
        raise NotImplementedError, "Implement #ask for Thor::Shell::HTML"
      end

      protected

        def can_display_colors?
          true
        end

        # Overwrite show_diff to show diff with colors if Diff::LCS is
        # available.
        #
        def show_diff(destination, content) #:nodoc:
          show_diff_common(destination, content)
        end

        def output_diff_line(diff) #:nodoc:
          output_diff_line_common(diff)
        end

        # Check if Diff::LCS is loaded. If it is, use it to create pretty output
        # for diff.
        #
        def diff_lcs_loaded? #:nodoc:
          diff_lcs_loaded_common?
        end

    end
  end
end
