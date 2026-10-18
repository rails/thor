class Thor
  # A declared dependency of one command on another, created by the
  # +requires+ class macro:
  #
  #   desc "publish", "Publish the built package"
  #   method_option :target, type: :string, required: true
  #   method_option :env, type: :string, default: "development"
  #   requires :build, args: ->(args, options) { [options[:target]] }
  #   def publish
  #     # runs after :build has run
  #   end
  #
  # +name+ is the command to run first: a command in the same class, or a
  # "namespace:command" string naming a command of another Thor class.
  # +args+ and +options+ map the current invocation into the required
  # command; each can be a static Array/Hash or a callable receiving the
  # current invocation's (args, options). Options declared by both commands
  # auto-pass by name; an explicit +options+ mapping merges over them.
  #
  # The class also owns the resolution of requirement names and the walk of
  # the requirement graph used by Thor.validate_requirements!.
  class Requirement
    class << self
      # Runs the requirements of +command+ on +instance+ before its body,
      # in declaration order. +stack+ is the list of [klass, command_name]
      # pairs whose requirements are in progress; it travels with the
      # invocation so cycles across classes are detected. Does nothing when
      # the command has no requirements or when the command line is
      # malformed: the usage error must come first, with no side effects.
      def satisfy_all(instance, command, command_args, stack) #:nodoc:
        requirements = command.requirements
        return if requirements.nil? || requirements.empty?
        return unless accepts?(instance, command, command_args)

        stack.push([instance.class, command.name])
        begin
          requirements.each { |requirement| requirement.satisfy(instance, command, command_args, stack) }
        ensure
          stack.pop
        end
      end

      # Resolves a requirement name from +klass+ to [klass, command_name],
      # or nil when no such command exists. See +target+ for the rules.
      def resolve(klass, name) #:nodoc:
        target_klass, command_name = target(klass, name)
        target_klass && target_klass.all_commands[command_name] ? [target_klass, command_name] : nil
      end

      # The class and normalized command name a requirement name points at
      # from +klass+, whether or not the command exists; the class is nil
      # when no loaded Thor class has the namespace. A name without ":" is
      # a command of +klass+; a "namespace:command" name is a command of
      # another loaded Thor class, inherited commands included. Dashes
      # normalize to underscores, as in +invoke+.
      def target(klass, name) #:nodoc:
        name = name.to_s
        return [klass, name.tr("-", "_")] unless name.include?(":")

        *pieces, command_name = name.split(":")
        namespace = pieces.join(":")
        namespace = "default" if namespace.empty?
        command_name = command_name.to_s.tr("-", "_")

        candidates = Thor::Base.subclasses.select { |candidate| candidate <= Thor && candidate.namespace == namespace }
        target_klass = candidates.detect { |candidate| candidate.all_commands[command_name] } || candidates.first
        [target_klass, command_name]
      end

      # The label of a command in requirement error messages.
      def label(klass, command_name) #:nodoc:
        klass.namespace.to_s.empty? ? command_name : "#{klass.namespace}:#{command_name}"
      end

      # Walks every requirement reachable from the commands of +klass+,
      # through other classes too, and returns one message per unresolved
      # name and per cycle. Runs no command.
      def problems(klass) #:nodoc:
        problems = []
        finished = []
        path = []

        visit = lambda do |node|
          if (index = path.index(node))
            chain = (path[index..-1] + [node]).map { |node_klass, name| label(node_klass, name) }
            problems << "Circular requirement: #{chain.join(' -> ')}"
            next
          end
          next if finished.include?(node)

          path.push(node)
          node_klass, command_name = node
          node_klass.all_commands[command_name].requirements.each do |requirement|
            target = resolve(node_klass, requirement.name)
            if target
              visit.call(target)
            else
              owner = node_klass == klass ? command_name : label(node_klass, command_name)
              problems << "Requirement #{requirement.name.inspect} of command #{owner.inspect} names a command that does not exist"
            end
          end
          path.pop
          finished << node
        end

        klass.all_commands.each_key { |command_name| visit.call([klass, command_name]) }
        problems
      end

      # Whether the command method on +instance+ accepts the given
      # positional arguments. Commands without a public method of their own
      # (method_missing) are not checked.
      def accepts?(instance, command, command_args) #:nodoc:
        return true if (instance.public_methods & [command.name.to_s, command.name.to_sym]).empty?

        parameters = instance.method(command.name).parameters
        required = parameters.count { |type, _| type == :req }
        optional = parameters.count { |type, _| type == :opt }
        rest = parameters.any? { |type, _| type == :rest }
        command_args.size >= required && (rest || command_args.size <= required + optional)
      end

      # The declared option keys a command accepts: its own plus its class's.
      def option_keys(klass, command) #:nodoc:
        klass.class_options.keys + command.options.keys
      end
    end

    attr_reader :name

    def initialize(name, args: nil, options: nil)
      unless (name.is_a?(Symbol) || name.is_a?(String)) && !name.to_s.empty?
        raise ArgumentError, "requires takes command names, not #{name.inspect}"
      end
      unless args.nil? || args.is_a?(Array) || args.respond_to?(:call)
        raise ArgumentError, "requires args: expects an Array or a callable, got #{args.inspect}"
      end
      unless options.nil? || options.is_a?(Hash) || options.respond_to?(:call)
        raise ArgumentError, "requires options: expects a Hash or a callable, got #{options.inspect}"
      end

      @name = name.to_s
      @args = args
      @options = options
    end

    # Runs the required command on behalf of +command+, through +invoke+ on
    # +instance+, so a command that already ran in this invocation is
    # skipped. A missing command, a cycle, or a Thor::Error from the
    # required command raises RequirementError with the original error as
    # cause. Other exceptions propagate unchanged.
    def satisfy(instance, command, command_args, stack) #:nodoc:
      klass, command_name = self.class.resolve(instance.class, name)
      raise undefined_error(instance.class) unless klass

      if stack.include?([klass, command_name])
        chain = (stack + [[klass, command_name]]).map { |node_klass, node_name| self.class.label(node_klass, node_name) }
        raise RequirementError, "Circular requirement: #{chain.join(' -> ')}"
      end

      target = klass.all_commands[command_name]
      source_names = self.class.option_keys(instance.class, command).map(&:to_s)
      declared_keys = self.class.option_keys(klass, target)
      shared_keys = declared_keys.select { |key| source_names.include?(key.to_s) }
      current_options = instance.options

      instance.invoke(
        klass, command_name,
        args_for(command_args.dup, current_options),
        options_for(command_args.dup, current_options, shared_keys, declared_keys)
      )
    rescue RequirementError
      raise
    rescue Thor::Error => e
      message = "Requirement #{name.inspect} of command #{command.name.inspect} failed: #{e.message}"
      if stack.length > 1
        last = klass ? self.class.label(klass, command_name) : name
        chain = stack.map { |node_klass, node_name| self.class.label(node_klass, node_name) } + [last]
        message = "#{message}\nRequirements: #{chain.join(' -> ')}"
      end
      raise RequirementError, message
    end

    # Positional arguments to pass to the required command.
    def args_for(current_args, current_options)
      resolved = resolve(@args, current_args, current_options)
      return [] if resolved.nil?
      unless resolved.is_a?(Array)
        raise ArgumentError, "requires args: for #{name.inspect} must resolve to an Array, got #{resolved.inspect}"
      end
      resolved
    end

    # Options to pass to the required command: options shared by name between
    # both commands auto-pass, then the explicit mapping (if any) merges over.
    #
    # +shared_keys+ are the required command's declared option keys that the
    # current command also declares; +declared_keys+ are all of the required
    # command's declared option keys. The hash is keyed with those declared
    # keys so the required command's option parser recognizes the values.
    def options_for(current_args, current_options, shared_keys, declared_keys = shared_keys)
      passed = {}
      shared_keys.each do |key|
        passed[key] = current_options[key] if current_options.key?(key)
      end

      explicit = resolve(@options, current_args, current_options)
      return passed if explicit.nil?
      unless explicit.is_a?(Hash)
        raise ArgumentError, "requires options: for #{name.inspect} must resolve to a Hash, got #{explicit.inspect}"
      end
      explicit.each do |key, value|
        declared = declared_keys.find { |declared_key| declared_key.to_s == key.to_s }
        passed[declared || key] = value
      end
      passed
    end

  private

    def resolve(mapping, args, options)
      mapping.respond_to?(:call) ? mapping.call(args, options) : mapping
    end

    # The error for a name that resolves to no command, with a did-you-mean
    # dictionary from the class the name points at.
    def undefined_error(source_klass)
      return UndefinedCommandError.new(name, source_klass.all_commands.keys, nil) unless name.include?(":")

      klass, = self.class.target(source_klass, name)
      return UndefinedCommandError.new(name, [], nil) unless klass

      dictionary = klass.all_commands.keys.map { |key| "#{klass.namespace}:#{key}" }
      UndefinedCommandError.new(name, dictionary, klass.namespace)
    end
  end
end
