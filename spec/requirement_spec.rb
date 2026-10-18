require "helper"
require "thor/runner"

describe "Thor requirements" do
  before do
    Reqs.reset
  end

  def journal
    Reqs.journal
  end

  describe ".requires" do
    it "rejects a declaration without command names" do
      expect do
        Class.new(Thor) do
          desc "broken", "broken"
          requires
          def broken; end
        end
      end.to raise_error(ArgumentError, "requires expects at least one command name")
    end

    it "rejects a value that is not a command name" do
      expect do
        Class.new(Thor) do
          desc "broken", "broken"
          requires 42
          def broken; end
        end
      end.to raise_error(ArgumentError, "requires takes command names, not 42")
    end

    it "rejects an empty name" do
      expect do
        Class.new(Thor) do
          desc "broken", "broken"
          requires ""
          def broken; end
        end
      end.to raise_error(ArgumentError, 'requires takes command names, not ""')
    end

    it "rejects args:/options: mappings combined with several names" do
      expect do
        Class.new(Thor) do
          desc "broken", "broken"
          requires :a, :b, args: ["v1"]
          def broken; end
        end
      end.to raise_error(ArgumentError, /single command/)
    end

    it "rejects args: that is not an Array or a callable" do
      expect do
        Class.new(Thor) do
          desc "broken", "broken"
          requires :a, args: "v1"
          def broken; end
        end
      end.to raise_error(ArgumentError, /args: expects an Array or a callable/)
    end

    it "rejects options: that is not a Hash or a callable" do
      expect do
        Class.new(Thor) do
          desc "broken", "broken"
          requires :a, options: [:target]
          def broken; end
        end
      end.to raise_error(ArgumentError, /options: expects a Hash or a callable/)
    end

    it "records requirements on the command in declaration order" do
      names = ReqsPipeline.all_commands["release"].requirements.map(&:name)
      expect(names).to eq(%w(package ship))
    end

    it "leaves commands without requirements with an empty list" do
      expect(ReqsPipeline.all_commands["fetch"].requirements).to eq([])
    end

    it "does not leak pending requirements into the next command" do
      expect(ReqsPipeline.all_commands["hopeless"].requirements).to eq([])
    end

    it "is inherited with the command" do
      expect(ReqsChild.all_commands["verify"].requirements.map(&:name)).to eq(%w(compile))
    end

    it "is dropped when a subclass redeclares the command" do
      expect(ReqsChild.all_commands["ship"].requirements).to eq([])
    end

    it "is copied when a command is duplicated" do
      copy = ReqsPipeline.all_commands["release"].dup
      expect(copy.requirements).to eq(ReqsPipeline.all_commands["release"].requirements)
      expect(copy.requirements).not_to equal(ReqsPipeline.all_commands["release"].requirements)
    end

    it "keeps the name as declared" do
      expect(ReqsPipeline.all_commands["dashed"].requirements.map(&:name)).to eq(%w(fetch-twice))
    end

    it "is not available on Thor::Group" do
      expect(Thor::Group).not_to respond_to(:requires)
      expect(Thor::Group).not_to respond_to(:validate_requirements!)
    end
  end

  describe "execution" do
    it "runs a required command before the requiring command's body" do
      ReqsPipeline.start(%w(verify))
      expect(journal).to eq([[:compile, nil, nil], [:verify]])
    end

    it "runs several requirements in declaration order" do
      ReqsPipeline.start(%w(package))
      expect(journal).to eq([[:fetch, "dev"], [:compile, nil, nil], [:package]])
    end

    it "composes requirements recursively and runs a command required twice once" do
      ReqsPipeline.start(%w(release))
      expect(journal).to eq([[:fetch, "dev"], [:compile, nil, nil], [:package], [:ship], [:release]])
    end

    it "resolves sibling requirements depth-first" do
      ReqsPipeline.start(%w(two_branch))
      expect(journal).to eq([[:branch_a1], [:branch_a], [:branch_b1], [:branch_b], [:two_branch]])
    end

    it "runs a command listed twice in one declaration once" do
      ReqsPipeline.start(%w(double))
      expect(journal).to eq([[:fetch, "dev"], [:double]])
    end

    it "runs a command of another class once when required directly and through another requirement" do
      ReqsPipeline.start(%w(twice_cross))
      expect(journal).to eq([[:tools_prep, "dev"], [:cross], [:twice_cross]])
    end

    it "resolves a namespaced name to a command the other class inherits" do
      ReqsPipeline.start(%w(via_child))
      expect(journal).to eq([[:fetch, "dev"], [:via_child]])
    end

    it "does not touch the requirement stack for a command without requirements" do
      instance = ReqsPipeline.new
      instance.invoke_command(ReqsPipeline.all_commands["fetch"], [])
      expect(instance.send(:_shared_configuration)[:requirement_stack]).to eq([])
    end

    it "skips a command that already ran even when required again with other arguments" do
      ReqsPipeline.start(%w(conflicting))
      expect(journal).to eq([[:compile, "first", nil], [:static_ship], [:conflicting]])
    end

    it "runs the requirements of a command invoked from another command's body" do
      ReqsPipeline.start(%w(invoker))
      expect(journal).to eq([[:invoker], [:compile, nil, nil], [:verify]])
    end

    it "runs inherited requirements for a subclass" do
      ReqsChild.start(%w(verify))
      expect(journal).to eq([[:compile, nil, nil], [:verify]])
    end

    it "resolves a dashed name to the underscored command" do
      ReqsPipeline.start(%w(dashed))
      expect(journal).to eq([[:fetch_twice], [:dashed]])
    end

    it "runs a requirement through Thor::Runner" do
      allow(YAML).to receive(:load_file).and_return({})
      Thor::Runner.start(%w(reqs_pipeline:verify))
      expect(journal).to eq([[:compile, nil, nil], [:verify]])
    end

    it "does not run requirements for help" do
      capture(:stdout) { ReqsPipeline.start(%w(help release)) }
      expect(journal).to be_empty
    end

    it "does not run requirements when the command is called with too few arguments" do
      stderr = capture(:stderr) do
        expect { ReqsPipeline.start(%w(takes)) }.to raise_error(SystemExit)
      end
      expect(stderr).to include('takes" was called with no arguments')
      expect(journal).to be_empty
    end

    it "does not run requirements when the command is called with too many arguments" do
      stderr = capture(:stderr) do
        expect { ReqsPipeline.start(%w(fetch extra)) && ReqsPipeline.start(%w(takes one two)) }.to raise_error(SystemExit)
      end
      expect(stderr).to include("was called with arguments")
      expect(journal).to be_empty
    end

    it "runs requirements when the arguments are well formed" do
      ReqsPipeline.start(%w(takes one))
      expect(journal).to eq([[:fetch, "dev"], [:takes, "one"]])
    end

    it "lets a command whose requirement failed run again on a later invoke" do
      ReqsPipeline.start(%w(retrier))
      expect(journal).to eq([[:rescued], [:rescued_again]])
    end

    it "does not let an args: callable mutate the current arguments" do
      ReqsPipeline.start(%w(mutator))
      expect(journal).to eq([[:compile, "v1", nil], [:mutator]])
    end
  end

  describe "arguments and options" do
    it "maps args: and options: lambdas from the current invocation" do
      ReqsPipeline.start(%w(ship --target 1))
      expect(journal).to eq([[:compile, "v1", "mapped"], [:ship]])
    end

    it "maps static args: and options:" do
      ReqsPipeline.start(%w(static_ship))
      expect(journal).to eq([[:compile, "v9", "static"], [:static_ship]])
    end

    it "auto-passes an option declared by both commands" do
      ReqsPipeline.start(%w(verify --target shared))
      expect(journal).to eq([[:compile, nil, "shared"], [:verify]])
    end

    it "auto-passes a class option" do
      ReqsPipeline.start(%w(package --env staging))
      expect(journal.first).to eq([:fetch, "staging"])
    end

    it "auto-passes options into a command of another class" do
      ReqsPipeline.start(%w(cross --env staging))
      expect(journal).to eq([[:tools_prep, "staging"], [:cross]])
    end

    it "does not pass options the required command does not declare" do
      ReqsPipeline.start(%w(insulated --undeclared secret))
      expect(journal).to eq([[:tools_isolated, nil], [:insulated]])
    end

    it "does not pass the requiring command's own arguments" do
      ReqsPipeline.start(%w(verify))
      expect(journal.first).to eq([:compile, nil, nil])
    end

    it "lets an explicit options: mapping win over an auto-passed option" do
      ReqsPipeline.start(%w(ship --target 1))
      expect(journal.first).to eq([:compile, "v1", "mapped"])
    end

    it "auto-passes a required option so the required command's check passes" do
      ReqsPipeline.start(%w(supplier --must yes))
      expect(journal).to eq([[:demanding, "yes"], [:supplier]])
    end

    it "satisfies a required option through an explicit options: mapping" do
      ReqsPipeline.start(%w(supplier_mapped))
      expect(journal).to eq([[:demanding, "mapped"], [:supplier_mapped]])
    end

    it "applies the required command's own default when nothing is passed" do
      ReqsPipeline.start(%w(needs_defaulted))
      expect(journal).to eq([[:defaulted, "info"], [:needs_defaulted]])
    end

    it "raises ArgumentError when an args: callable does not return an Array" do
      expect { ReqsPipeline.start(%w(bad_args)) }.to raise_error(ArgumentError, /args: for "compile" must resolve to an Array/)
      expect(journal).to be_empty
    end

    it "raises ArgumentError when an options: callable does not return a Hash" do
      expect { ReqsPipeline.start(%w(bad_options)) }.to raise_error(ArgumentError, /options: for "compile" must resolve to a Hash/)
      expect(journal).to be_empty
    end

    it "applies the required command's option validation" do
      stderr = capture(:stderr) do
        expect { ReqsPipeline.start(%w(strict)) }.to raise_error(SystemExit)
      end
      expect(stderr).to include('Requirement "demanding" of command "strict" failed')
      expect(stderr).to include("--must")
      expect(journal).to be_empty
    end
  end

  describe "errors" do
    def start_and_capture(args)
      stderr = capture(:stderr) do
        expect { ReqsPipeline.start(args) }.to raise_error(SystemExit)
      end
      stderr
    end

    it "raises RequirementError when a required command fails with a Thor::Error" do
      expect { ReqsPipeline.new.invoke(:doomed) }.to raise_error(Thor::RequirementError) { |error|
        expect(error.message).to eq('Requirement "hopeless" of command "doomed" failed: cannot continue')
        expect(error.cause).to be_a(Thor::Error)
        expect(error.cause.message).to eq("cannot continue")
      }
      expect(journal).to be_empty
    end

    it "names the whole chain when the failure is deeper than one level" do
      expect { ReqsPipeline.new.invoke(:deep) }.to raise_error(Thor::RequirementError) { |error|
        expect(error.message).to eq(
          "Requirement \"hopeless\" of command \"doomed\" failed: cannot continue\n" \
          "Requirements: reqs_pipeline:deep -> reqs_pipeline:doomed -> reqs_pipeline:hopeless"
        )
      }
    end

    it "prints the failure and does not run the body" do
      stderr = start_and_capture(%w(doomed))
      expect(stderr).to include('Requirement "hopeless" of command "doomed" failed: cannot continue')
      expect(journal).to be_empty
    end

    it "lets a developer error in a required command propagate unchanged" do
      expect { ReqsPipeline.start(%w(buggy)) }.to raise_error(RuntimeError, "the pipeline is on fire")
      expect(journal).to be_empty
    end

    it "raises RequirementError with UndefinedCommandError as cause for an unknown name" do
      expect { ReqsPipeline.new.invoke(:vague) }.to raise_error(Thor::RequirementError) { |error|
        expect(error.message).to start_with('Requirement "no_such_command" of command "vague" failed: Could not find command "no_such_command".')
        expect(error.cause).to be_a(Thor::UndefinedCommandError)
      }
      expect(journal).to be_empty
    end

    it "suggests a command of the other class for an unknown namespaced name" do
      expect { ReqsPipeline.new.invoke(:vague_cross) }.to raise_error(Thor::RequirementError) { |error|
        expect(error.message).to include('Could not find command "reqs_tools:nope" in "reqs_tools" namespace.')
        expect(error.message).to include("reqs_tools:prep") if Thor::Correctable
      }
    end

    it "raises RequirementError for a namespace that does not exist" do
      expect { ReqsPipeline.new.invoke(:vague_namespace) }.to raise_error(Thor::RequirementError, /Could not find command "no_such_namespace:prep"/)
    end

    it "names the chain when the unknown name is deeper than one level" do
      expect { ReqsPipeline.new.invoke(:deep_vague) }.to raise_error(Thor::RequirementError) { |error|
        expect(error.message).to include('Requirement "no_such_command" of command "vague" failed')
        expect(error.message).to end_with("Requirements: reqs_pipeline:deep_vague -> reqs_pipeline:vague -> no_such_command")
      }
    end

    it "raises RequirementError for a cycle across classes" do
      expect { ReqsPipeline.new.invoke(:loop_b) }.to raise_error(
        Thor::RequirementError, "Circular requirement: reqs_pipeline:loop_b -> reqs_tools:loop_a -> reqs_pipeline:loop_b"
      )
      expect(journal).to be_empty
    end

    it "raises RequirementError for a command that requires itself" do
      expect { ReqsPipeline.new.invoke(:selfish) }.to raise_error(
        Thor::RequirementError, "Circular requirement: reqs_pipeline:selfish -> reqs_pipeline:selfish"
      )
      expect(journal).to be_empty
    end

    it "raises RequirementError for an indirect cycle" do
      expect { ReqsPipeline.new.invoke(:ping) }.to raise_error(
        Thor::RequirementError, "Circular requirement: reqs_pipeline:ping -> reqs_pipeline:pong -> reqs_pipeline:ping"
      )
      expect(journal).to be_empty
    end

    it "is printed by start like other Thor errors" do
      stderr = start_and_capture(%w(ping))
      expect(stderr).to include("Circular requirement: reqs_pipeline:ping -> reqs_pipeline:pong -> reqs_pipeline:ping")
    end
  end

  describe ".validate_requirements!" do
    it "returns true when every requirement resolves" do
      expect(ReqsClean.validate_requirements!).to be true
    end

    it "lists every unresolved name and cycle once" do
      expect { ReqsPipeline.validate_requirements! }.to raise_error(Thor::RequirementError) { |error|
        expect(error.message.split("\n")).to match_array([
          'Requirement "no_such_command" of command "vague" names a command that does not exist',
          'Requirement "reqs_tools:nope" of command "vague_cross" names a command that does not exist',
          'Requirement "no_such_namespace:prep" of command "vague_namespace" names a command that does not exist',
          "Circular requirement: reqs_pipeline:selfish -> reqs_pipeline:selfish",
          "Circular requirement: reqs_pipeline:ping -> reqs_pipeline:pong -> reqs_pipeline:ping",
          "Circular requirement: reqs_pipeline:loop_b -> reqs_tools:loop_a -> reqs_pipeline:loop_b",
        ])
      }
    end

    it "follows requirements into other classes" do
      expect { ReqsTools.validate_requirements! }.to raise_error(
        Thor::RequirementError, "Circular requirement: reqs_tools:loop_a -> reqs_pipeline:loop_b -> reqs_tools:loop_a"
      )
    end

    it "does not run any command" do
      begin
        ReqsPipeline.validate_requirements!
      rescue Thor::RequirementError
        nil
      end
      expect(journal).to be_empty
    end
  end

  describe "help" do
    it "lists a command's direct requirements" do
      content = capture(:stdout) { ReqsPipeline.start(%w(help release)) }
      expect(content).to include("Requirements:\n  package\n  ship\n")
    end

    it "shows namespaced requirements as declared" do
      content = capture(:stdout) { ReqsPipeline.start(%w(help cross)) }
      expect(content).to include("Requirements:\n  reqs_tools:prep\n")
    end

    it "shows dashed names as declared" do
      content = capture(:stdout) { ReqsPipeline.start(%w(help dashed)) }
      expect(content).to include("Requirements:\n  fetch-twice\n")
    end

    it "prints no section for a command without requirements" do
      content = capture(:stdout) { ReqsPipeline.start(%w(help fetch)) }
      expect(content).not_to include("Requirements:")
    end
  end
end
