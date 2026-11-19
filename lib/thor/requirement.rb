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
      # Runs requirements before the command body, unless its arguments are invalid.
      # The invocation stack is shared for cycle detection.
      def satisfy_all(instance, command, command_args, stack) #:nodoc:
        requirements = command.requirements
        return if requirements.nil? || requirements.empty?
        return unless command.accepts_arguments?(instance, command_args)

        stack.push([instance.class, command.name])
        begin
          requirements.each { |requirement| requirement.satisfy(instance, command, command_args, stack) }
        ensure
          stack.pop
        end
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
            target_klass, target_name, target_command = requirement.resolve(node_klass)
            if target_command
              visit.call([target_klass, target_name])
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
    end

    attr_reader :name

    def initialize(name, args: nil, options: nil)
      validate_command_name!(name)
      validate_args_mapping!(args)
      validate_options_mapping!(options)

      @name = name.to_s
      @args = args
      @options = options
    end

    # Returns the target class, command name, and command, if it exists.
    def resolve(klass) #:nodoc:
      target_klass, command_name = target(klass)
      command = target_klass && target_klass.all_commands[command_name]
      [target_klass, command_name, command]
    end

    # Runs the requirement through +invoke+, preserving Thor's once-per-run rule.
    def satisfy(instance, command, command_args, stack) #:nodoc:
      klass, command_name, target = resolve(instance.class)
      raise undefined_error(instance.class, klass) unless target

      raise_if_circular_requirement!(klass, command_name, stack)

      source_names = option_keys(instance.class, command).map(&:to_s)
      declared_keys = option_keys(klass, target)
      current_options = instance.options

      instance.invoke(
        klass, command_name,
        args_for(command_args.dup, current_options),
        options_for(command_args.dup, current_options, source_names, declared_keys)
      )
    rescue RequirementError
      raise
    rescue Thor::Error => e
      message = "Requirement #{name.inspect} of command #{command.name.inspect} failed: #{e.message}"
      if stack.length > 1
        last = target ? self.class.label(klass, command_name) : name
        chain = command_labels(stack) + [last]
        message = "#{message}\nRequirements: #{chain.join(' -> ')}"
      end
      raise RequirementError, message
    end

  private

    def raise_if_circular_requirement!(klass, command_name, stack)
      return unless stack.include?([klass, command_name])

      chain = command_labels(stack + [[klass, command_name]])
      raise RequirementError, "Circular requirement: #{chain.join(' -> ')}"
    end

    def command_labels(stack)
      stack.map { |node_klass, node_name| self.class.label(node_klass, node_name) }
    end

    def validate_command_name!(name)
      unless [ Symbol, String ].any? { |klass| name.is_a?(klass) } && !name.to_s.empty?
        raise ArgumentError, "Expected a command name for requires, got #{name.inspect}"
      end
    end

    def validate_args_mapping!(args)
      unless args.nil? || args.is_a?(Array) || args.respond_to?(:call)
        raise ArgumentError, "Expected an Array or a callable for args:, got #{args.inspect}"
      end
    end

    def validate_options_mapping!(options)
      unless options.nil? || options.is_a?(Hash) || options.respond_to?(:call)
        raise ArgumentError, "Expected a Hash or a callable for options:, got #{options.inspect}"
      end
    end

    # Returns the target class even if the command does not exist.
    def target(klass)
      requirement_name = name.to_s
      return [klass, requirement_name.tr("-", "_")] unless requirement_name.include?(":")

      *pieces, command_name = requirement_name.split(":")
      namespace = pieces.join(":")
      namespace = "default" if namespace.empty?
      command_name = command_name.to_s.tr("-", "_")

      candidates = Thor::Base.subclasses.select { |candidate| candidate <= Thor && candidate.namespace == namespace }
      target_klass = candidates.detect { |candidate| candidate.all_commands[command_name] } || candidates.first
      [target_klass, command_name]
    end

    # The declared option keys a command accepts: its own plus its class's.
    def option_keys(klass, command)
      klass.class_options.keys + command.options.keys
    end

    # Positional arguments to pass to the required command.
    def args_for(current_args, current_options)
      resolved = resolve_mapping(@args, current_args, current_options)
      return [] if resolved.nil?
      unless resolved.is_a?(Array)
        raise ArgumentError, "Expected args: for #{name.inspect} to resolve to an Array, got #{resolved.inspect}"
      end
      resolved
    end

    # Explicit mappings override shared options. Preserve the declared keys
    # so the target command's option parser recognizes them.
    def options_for(current_args, current_options, source_names, declared_keys)
      passed = {}
      declared_keys.each do |key|
        next unless source_names.include?(key.to_s) && current_options.key?(key)
        passed[key] = current_options[key]
      end

      explicit = resolve_mapping(@options, current_args, current_options)
      return passed if explicit.nil?
      unless explicit.is_a?(Hash)
        raise ArgumentError, "Expected options: for #{name.inspect} to resolve to a Hash, got #{explicit.inspect}"
      end
      explicit.each do |key, value|
        declared = declared_keys.find { |declared_key| declared_key.to_s == key.to_s }
        passed[declared || key] = value
      end
      passed
    end

    def resolve_mapping(mapping, args, options)
      mapping.respond_to?(:call) ? mapping.call(args, options) : mapping
    end

    # The error for a name that resolves to no command, with a did-you-mean
    # dictionary from the class the name points at.
    def undefined_error(source_klass, klass)
      return UndefinedCommandError.new(name, source_klass.all_commands.keys, nil) unless name.include?(":")

      return UndefinedCommandError.new(name, [], nil) unless klass

      dictionary = klass.all_commands.keys.map { |key| "#{klass.namespace}:#{key}" }
      UndefinedCommandError.new(name, dictionary, klass.namespace)
    end
  end
end
