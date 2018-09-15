class Thor
  class Thor2 < Thor
    # This is a class to use instead of Thor when declaring your CLI
    # This alternative works the same way as Thor, but has more common defaults:
    #  * If there is a failure in the argument parsing and other Thor-side
    #    things, the exit code will be non-zero
    #  * Things that look like options but are not valid options will
    #    will show an error of being unknown option instead of being
    #    used as arguments.
    #  * Make sure the default value of options is of the correct type
    # For backward compatibility reasons, these cannot be made default in
    # the regular `Thor` class
    #
    # This class is available in the top-level as Thor2, so you can do
    # class MyCli < Thor2
    #   ...
    # end

    # Fail on unknown options instead of treating them as argument
    check_unknown_options!

    # Make sure the default value of options is of the correct type
    check_default_type!

    # All failures should result in non-zero error code
    def self.exit_on_failure?
      true
    end
  end
end

::Thor2 = Thor::Thor2
