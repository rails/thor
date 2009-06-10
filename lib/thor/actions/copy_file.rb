class Thor
  module Actions

    def copy_file
    end

    class CopyFile #:nodoc:

      attr_accessor :base, :source, :destination
  
      def source=(source)
        unless source.blank?
          @source = ::File.expand_path(source, base.source_root)
        end
      end
      
      def destination=(destination)
        unless destination.blank?
          @destination = ::File.expand_path(convert_encoded_instructions(destination), base.destination_root)
        end
      end

      # Copies a new file from source to destination.
      #
      # ==== Parameters
      # source<String>:: Full path to the source of this file
      # destination<String>:: Full path to the destination of this file
      #
      def initialize(source, destination)
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
