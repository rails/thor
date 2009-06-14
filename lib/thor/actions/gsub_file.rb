class Thor
  module Actions

    # Run a regular expression replacement on a file.
    #
    # ==== Parameters
    # path<String>:: path of the file to be changed
    # flag<Regexp|String>:: the regexp or string to be replaced
    # replacement<String>:: the replacement, can be also given as a block
    # log_status<Boolean>:: if false, does not log the status. True by default.
    #                       If a symbol is given, uses it as the output color.
    #
    # ==== Example
    #
    #   gsub_file 'app/controllers/application_controller.rb', /#\s*(filter_parameter_logging :password)/, '\1'
    #
    #   gsub_file 'README', /rake/, :green do |match|
    #     match << " no more. Use thor!"
    #   end
    #
    def gsub_file(path, flag, *args, &block)
      log_status = args.last.is_a?(Symbol) || [ true, false ].include?(args.last) ? args.pop : true

      path = File.expand_path(path, root)
      say_status_if_log :gsub, relative_to_absolute_root(path), log_status

      unless options[:pretend]
        content = File.read(path)
        content.gsub!(flag, *args, &block)
        File.open(path, 'wb') { |file| file.write(content) }
      end
    end

    # Append text to a file.
    #
    # ==== Parameters
    # path<String>:: path of the file to be changed
    # data<String>:: the data to append to the file, can be also given as a block.
    # log_status<Boolean>:: if false, does not log the status. True by default.
    #                       If a symbol is given, uses it as the output color.
    #
    # ==== Example
    #
    #   append_file 'config/environments/test.rb', 'config.gem "rspec"'
    #
    def append_file(path, data=nil, log_status=true, &block)
      path = File.expand_path(path, root)
      say_status_if_log :append, relative_to_absolute_root(path), log_status

      File.open(path, 'ab') { |file| file.write(data || block.call) } unless options[:pretend]
    end

    # Prepend text to a file.
    #
    # ==== Parameters
    # path<String>:: path of the file to be changed
    # data<String>:: the data to prepend to the file, can be also given as a block.
    # log_status<Boolean>:: if false, does not log the status. True by default.
    #                       If a symbol is given, uses it as the output color.
    #
    # ==== Example
    #
    #   prepend_file 'config/environments/test.rb', 'config.gem "rspec"'
    #
    def prepend_file(path, data=nil, log_status=true, &block)
      path = File.expand_path(path, root)
      say_status_if_log :prepend, relative_to_absolute_root(path), log_status

      unless options[:pretend]
        content = data || block.call
        content << File.read(path)
        File.open(path, 'wb') { |file| file.write(content) }
      end
    end

  end
end
