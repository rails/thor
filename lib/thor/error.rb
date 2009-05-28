class Thor
  # Thor::Error are used when it is provoked by the user who is invoking a task
  # or generator gave the wrong input. All other errors are not rescued.
  #
  class Error < StandardError; end
end
