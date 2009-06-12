class Thor
  module Actions

    # This is the base class for templater actions, ie. that copies something
    # from some directory (source) to another (destination).
    #
    # This implementation is completely based in the Templater actions,
    # created by Jonas Nicklas and Michael S. Klishin under MIT LICENSE.
    #
    class Templater #:nodoc:
      attr_reader :base, :source, :destination, :relative_destination

      # Initializes given the source and destination.
      #
      # ==== Parameters
      # source<String>:: Full path to the source of this file
      # destination<String>:: Full path to the destination of this file
      #
      def initialize(base, source, destination)
        @base = base
        self.source = source
        self.destination = destination
      end

      # Returns the contents of the source file as a String. If render is
      # available, a diff option is shown in the file collision menu.
      #
      # ==== Returns
      # String:: The source file.
      #
      # def render
      #   raise NotImplementedError
      # end

      # Checks if the destination file already exists.
      #
      # ==== Returns
      # Boolean:: true if the file exists, false otherwise.
      #
      def exists?
        raise NotImplementedError
      end

      # Checks if the content of the file at the destination is identical to the rendered result.
      #
      # ==== Returns
      # Boolean:: true if it is identical, false otherwise.
      #
      def identical?
        raise NotImplementedError
      end

      # Invokes the action.
      #
      def invoke!
        raise NotImplementedError
      end

      # Revokes the action
      #
      def revoke!
        raise NotImplementedError
      end

      protected

        # Sets the source value from a relative source value.
        #
        def source=(source)
          if source
            @source = ::File.expand_path(source, base.source_root)
          end
        end

        # Sets the destination value from a relative destination value. The
        # relative destination is kept to be used in output messages.
        #
        def destination=(destination)
          if destination
            @relative_destination = destination
            @destination = ::File.expand_path(destination, base.destination_root)
          end
        end

        # Receives a hash of options and just execute the block if some
        # conditions are met.
        #
        def invoke_with_options!(options, &block)
          if identical?
            say_status :identical, :blue
          elsif exists?
            force_or_skip_or_conflict(options[:force], options[:skip], &block)
          else
            say_status :created, :green
            block.call unless options[:pretend]
          end
        end

        # If force is true, run the action, otherwise check if it's not being
        # skipped. If both are false, show the file_collision menu, if the menu
        # returns true, force it, otherwise skip.
        #
        def force_or_skip_or_conflict(force, skip, &block)
          if force
            say_status :forced, :yellow
            block.call unless options[:pretend]
          elsif skip
            say_status :skipped, :yellow
          else
            say_status :conflict, :red
            force_or_skip_or_conflict(force_on_collision?, true, &block)
          end
        end

        # Asks the shell to show the file collision menu to the user.
        #
        def force_on_collision?
          if respond_to?(:render)
            shell.file_collision(destination){ render }
          else
            shell.file_collision(destination)
          end
        end

        # Retrieves the shell object from base class.
        #
        def shell
          base.shell
        end

        # Retrieves options hash from base class.
        #
        def options
          base.options
        end

        # Shortcut to say_status shell method.
        #
        def say_status(status, color)
          shell.say_status status, relative_destination, color
        end

    end
  end
end
