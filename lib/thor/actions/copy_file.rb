class Thor
  module Actions

    # Receives the source and the destination, relative to the source root and
    # destination root respectively.
    #
    def copy_file(source, destination=nil)
      action CopyFile.new(source, destination || source)
    end

    class CopyFile #:nodoc:
      attr_accessor :base, :source, :destination

      def source=(source)
        if source
          @source = ::File.expand_path(source, base.source_root)
        end
      end

      def destination=(destination)
        if destination
          @destination = ::File.expand_path(destination, base.destination_root)
        end
      end

      # Copies a new file from source to destination.
      #
      # ==== Parameters
      # source<String>:: Full path to the source of this file
      # destination<String>:: Full path to the destination of this file
      #
      def initialize(base, source, destination)
        self.base = base
        self.source = source
        self.destination = destination
      end

      # Returns the contents of the source file as a String
      #
      # ==== Returns
      # String:: The source file.
      #
      def show
        ::File.read(source)
      end

      # Checks if the destination file already exists.
      #
      # ==== Returns
      # Boolean:: true if the file exists, false otherwise.
      #
      def exists?
        ::File.exists?(destination)
      end

      # Checks if the content of the file at the destination is identical to the rendered result.
      # 
      # ==== Returns
      # Boolean:: true if it is identical, false otherwise.
      #
      def identical?
        exists? && ::FileUtils.identical?(source, destination)
      end

      # Renders the template and copies it to the destination.
      #
      def invoke!
        ::FileUtils.mkdir_p(::File.dirname(destination))
        ::FileUtils.cp_r(source, destination)
      end

      # Removes the destination file
      #
      def revoke!
        ::FileUtils.rm_r(destination, :force => true)
      end

    end
  end
end
