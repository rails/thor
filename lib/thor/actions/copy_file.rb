class Thor
  module Actions

    # Copies the file from the relative source to the relative destination. If
    # the destination is not given it's assumed to be equal to the source.
    #
    # ==== Parameters
    # source<String>:: the relative path to the source root.
    # destination<String>:: the relative path to the destination root.
    # config<Hash>:: give :verbose => false to not log the status.
    #
    # ==== Examples
    #
    #   copy_file "README", "doc/README"
    #
    #   copy_file "doc/README"
    #
    def copy_file(source, destination=nil, config={})
      destination ||= source
      source = File.expand_path(find_in_source_paths(source.to_s))

      create_file destination, nil, config do
        File.read(source)
      end
    end
  end
end
