require 'thor/actions/directory'

class Thor
  module Actions

    def smart_directory(source, *args, &block)
      config = args.last.is_a?(Hash) ? args.pop : {}
      destination = args.first || source
      action SmartDirectory.new(self, source, destination || source, config, &block)
    end

    class SmartDirectory < Directory 

      private
      def _inject_into_template_counterpart(file_source, file_destination)
        temp_file = _create_temp_file(file_source, file_destination)
        _inject_temp_file_contents_into_real_file temp_file
        _delete_temp_file temp_file
      end

      def _create_temp_file(file_source, file_destination)
        base.template(file_source, file_destination, config, &@block).split("/")[1..(-1)].join("/")
      end

      def _inject_temp_file_contents_into_real_file(temp_file)
        contents = File.read File.join(destination, temp_file)
        target_file = temp_file[0..-4]
        full_target_filepath = File.join(destination, target_file) 
        error_msg = "Cannot load such a file -- #{target_file} -- did you forget to write a #{full_target_filepath}.tt file \n"
        error_msg += "destination: #{destination} | given_destination: #{given_destination} | target_file: #{target_file}"
        raise LoadError.new(error_msg) unless File.exist? full_target_filepath
        base.insert_into_file(File.join(given_destination, target_file), contents, :after => "###\n")
      end

      def _delete_temp_file(temp_file)
        File.unlink File.join(destination, temp_file)
      end

      protected

      def execute!
        lookup = Util.escape_globs(source)
        lookup = config[:recursive] ? File.join(lookup, '**') : lookup
        lookup = file_level_lookup(lookup)

        files(lookup).sort.each do |file_source|
          next if File.directory?(file_source)
          next if config[:exclude_pattern] && file_source.match(config[:exclude_pattern])
          file_destination = File.join(given_destination, file_source.gsub(source, '.'))
          file_destination.gsub!('/./', '/')

          case file_source
          when /\.empty_directory$/
            dirname = File.dirname(file_destination).gsub(/\/\.$/, '')
            next if dirname == given_destination
            base.empty_directory(dirname, config)
          when /\.tt$/
            destination = base.template(file_source, file_destination[0..-4], config, &@block)
          when /\.zc$/
            _inject_into_template_counterpart(file_source, file_destination)
          else
            destination = base.copy_file(file_source, file_destination, config, &@block) unless File.exist? file_destination
          end
        end
      end

    end

  end
end