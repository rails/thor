require 'thor/parser/argument'

class Thor
  class Arguments < Parser
  
    def initialize(arguments=[])
      @arguments = arguments
      @non_assigned_required = @arguments.select { |a| a.required? }
    end

    def parse(args)
      @pile, assigns = args.dup, {}

      @arguments.each do |argument|
        assigns[argument.human_name] = if peek
          parse_peek(argument.switch_name, argument)
        else
          argument.default
        end
      end

      check_requirement!
      assigns
    end

  end
end
