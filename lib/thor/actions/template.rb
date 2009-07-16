require 'erb'

class Thor
  module Actions

    # Gets an ERB template at the relative source, executes it and makes a copy
    # at the relative destination. If the destination is not given it's assumed
    # to be equal to the source removing .tt from the filename.
    #
    # ==== Parameters
    # source<String>:: the relative path to the source root.
    # destination<String>:: the relative path to the destination root.
    # config<Hash>:: give :verbose => false to not log the status.
    #
    # ==== Examples
    #
    #   template "README", "doc/README"
    #
    #   template "doc/README"
    #
    def template(source, destination=nil, config={})
      destination ||= source
      source  = File.expand_path(find_in_source_paths(source.to_s))
      context = instance_eval('binding')

      create_file destination, nil, config do
        ERB.new(::File.read(source), nil, '-').result(context)
      end
    end
  end
end
