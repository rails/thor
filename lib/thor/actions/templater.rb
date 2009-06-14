class Thor
  module Actions

    # This is the base class for templater actions, ie. that copies something
    # from some directory (source) to another (destination).
    #
    # This implementation is completely based in Templater actions, created
    # by Jonas Nicklas and Michael S. Klishin under MIT LICENSE.
    #
    class Templater #:nodoc:
      attr_reader :base, :source, :destination, :relative_destination

      # Initializes given the source and destination.
      #
      # ==== Parameters
      # base<Thor::Base>:: A Thor::Base instance
      # source<String>:: Relative path to the source of this file
      # destination<String>:: Relative path to the destination of this file
      # log_status<Boolean>:: If false, does not log the status. True by default.
      #                       Templater log status does not accept color.
      #
      def initialize(base, source, destination, log_status=true)
        @base, @log_status = base, log_status
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

        def pretend?
          base.options[:pretend]
        end

        # Sets the source value from a relative source value.
        #
        def source=(source)
          if source
            @source = ::File.expand_path(source.to_s, base.source_root)
          end
        end

        # Sets the destination value from a relative destination value. The
        # relative destination is kept to be used in output messages.
        #
        def destination=(destination)
          if destination
            @destination = ::File.expand_path(destination.to_s, base.destination_root)
            @relative_destination = base.relative_to_absolute_root(@destination)
          end
        end

        # Receives a hash of options and just execute the block if some
        # conditions are met.
        #
        def invoke_with_options!(options, &block)
          if identical?
            say_status :identical, :blue
          elsif exists?
            force_or_skip_or_conflict(options[:force], options[:skip], options[:pretend], &block)
          else
            say_status :create, :green
            block.call unless options[:pretend]
          end
        end

        # If force is true, run the action, otherwise check if it's not being
        # skipped. If both are false, show the file_collision menu, if the menu
        # returns true, force it, otherwise skip.
        #
        def force_or_skip_or_conflict(force, skip, pretend, &block)
          if force
            say_status :force, :yellow
            block.call unless pretend
          elsif skip
            say_status :skip, :yellow
          else
            say_status :conflict, :red
            force_or_skip_or_conflict(force_on_collision?, true, pretend, &block)
          end
        end

        # Asks the shell to show the file collision menu to the user.
        #
        def force_on_collision?
          if respond_to?(:render)
            base.shell.file_collision(destination){ render }
          else
            base.shell.file_collision(destination)
          end
        end

        # Shortcut to say_status shell method.
        #
        def say_status(status, color)
          base.shell.say_status status, relative_destination, color if @log_status
        end

        # TODO Add this behavior to all actions.
        #
        # def after_invoke
        #   # Optionally change permissions.
        #   if file_options[:chmod]
        #     FileUtils.chmod(file_options[:chmod], destination)
        #   end
        #
        #   # Optionally add file to subversion or git
        #   system("svn add #{destination}") if options[:svn]
        #   system("git add -v #{relative_destination}") if options[:git]
        # end

    end
  end
end
