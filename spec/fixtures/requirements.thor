module Reqs
  class << self
    def journal
      @journal ||= []
    end

    def reset
      @journal = []
    end
  end
end

class ReqsTools < Thor
  class_option :env, type: :string

  desc "prep", "A requirement living in another class"
  def prep
    Reqs.journal << [:tools_prep, options[:env]]
  end

  desc "isolated", "Declares no option shared with ReqsPipeline"
  def isolated
    Reqs.journal << [:tools_isolated, options[:undeclared]]
  end

  desc "loop_a", "Half of a cycle across classes"
  requires "reqs_pipeline:loop_b"
  def loop_a
    Reqs.journal << [:loop_a]
  end
end

class ReqsPipeline < Thor
  def self.exit_on_failure?
    true
  end

  class_option :env, type: :string, default: "dev"

  desc "fetch", "No requirements"
  def fetch
    Reqs.journal << [:fetch, options[:env]]
  end

  desc "compile [VERSION]", "Takes a positional and a target option"
  method_option :target, type: :string
  def compile(version = nil)
    Reqs.journal << [:compile, version, options[:target]]
  end

  desc "package", "Several requirements by name"
  requires :fetch, :compile
  def package
    Reqs.journal << [:package]
  end

  desc "ship", "A mapped requirement"
  method_option :target, type: :string, default: "unmapped"
  requires :compile, args: ->(args, options) { ["v#{options[:target]}"] }, options: {target: "mapped"}
  def ship
    Reqs.journal << [:ship]
  end

  desc "static_ship", "A statically mapped requirement"
  requires :compile, args: ["v9"], options: {"target" => "static"}
  def static_ship
    Reqs.journal << [:static_ship]
  end

  desc "verify", "Shares the target option with compile"
  method_option :target, type: :string
  requires :compile
  def verify
    Reqs.journal << [:verify]
  end

  desc "release", "Requirements accumulate and compose"
  requires :package
  requires :ship
  def release
    Reqs.journal << [:release]
  end

  desc "cross", "Requires a command in another class"
  requires "reqs_tools:prep"
  def cross
    Reqs.journal << [:cross]
  end

  desc "insulated", "Requires a command sharing no options"
  method_option :undeclared, type: :string
  requires "reqs_tools:isolated"
  def insulated
    Reqs.journal << [:insulated]
  end

  desc "dashed", "Requires a command by its dashed name"
  requires :"fetch-twice"
  def dashed
    Reqs.journal << [:dashed]
  end

  desc "fetch_twice", "Target of the dashed requirement"
  def fetch_twice
    Reqs.journal << [:fetch_twice]
  end

  desc "conflicting", "Requires compile twice with different args"
  requires :compile, args: ["first"]
  requires :static_ship
  def conflicting
    Reqs.journal << [:conflicting]
  end

  desc "invoker", "Invokes a requiring command from its body"
  def invoker
    Reqs.journal << [:invoker]
    invoke :verify
  end

  desc "doomed", "Requires a command that raises a Thor::Error"
  requires :hopeless
  def doomed
    Reqs.journal << [:doomed]
  end

  desc "hopeless", "Fails as a plain thor error"
  def hopeless
    raise Thor::Error, "cannot continue"
  end

  desc "deep", "Requires a command whose requirement fails"
  requires :doomed
  def deep
    Reqs.journal << [:deep]
  end

  desc "buggy", "Requires a command that raises a developer error"
  requires :bug
  def buggy
    Reqs.journal << [:buggy]
  end

  desc "bug", "Raises a RuntimeError"
  def bug
    raise "the pipeline is on fire"
  end

  desc "vague", "Requires a command that does not exist"
  requires :no_such_command
  def vague
    Reqs.journal << [:vague]
  end

  desc "vague_cross", "Requires a command another class does not have"
  requires "reqs_tools:nope"
  def vague_cross
    Reqs.journal << [:vague_cross]
  end

  desc "vague_namespace", "Requires a command in a namespace that does not exist"
  requires "no_such_namespace:prep"
  def vague_namespace
    Reqs.journal << [:vague_namespace]
  end

  desc "selfish", "Requires itself"
  requires :selfish
  def selfish
    Reqs.journal << [:selfish]
  end

  desc "ping", "Half of a cycle"
  requires :pong
  def ping
    Reqs.journal << [:ping]
  end

  desc "pong", "Other half of a cycle"
  requires :ping
  def pong
    Reqs.journal << [:pong]
  end

  desc "strict", "Requires a command with a required option it does not supply"
  requires :demanding
  def strict
    Reqs.journal << [:strict]
  end

  desc "demanding", "Has a required option"
  method_option :must, type: :string, required: true
  def demanding
    Reqs.journal << [:demanding, options[:must]]
  end

  desc "supplier", "Shares the required option of demanding"
  method_option :must, type: :string
  requires :demanding
  def supplier
    Reqs.journal << [:supplier]
  end

  desc "supplier_mapped", "Maps the required option of demanding"
  requires :demanding, options: {must: "mapped"}
  def supplier_mapped
    Reqs.journal << [:supplier_mapped]
  end

  desc "defaulted", "Has an option with a default"
  method_option :level, type: :string, default: "info"
  def defaulted
    Reqs.journal << [:defaulted, options[:level]]
  end

  desc "needs_defaulted", "Requires defaulted without sharing its option"
  requires :defaulted
  def needs_defaulted
    Reqs.journal << [:needs_defaulted]
  end

  desc "branch_a1", "Leaf of branch a"
  def branch_a1
    Reqs.journal << [:branch_a1]
  end

  desc "branch_a", "Branch a"
  requires :branch_a1
  def branch_a
    Reqs.journal << [:branch_a]
  end

  desc "branch_b1", "Leaf of branch b"
  def branch_b1
    Reqs.journal << [:branch_b1]
  end

  desc "branch_b", "Branch b"
  requires :branch_b1
  def branch_b
    Reqs.journal << [:branch_b]
  end

  desc "two_branch", "Two sibling requirements with their own requirements"
  requires :branch_a, :branch_b
  def two_branch
    Reqs.journal << [:two_branch]
  end

  desc "double", "Requires the same command twice"
  requires :fetch, :fetch
  def double
    Reqs.journal << [:double]
  end

  desc "twice_cross", "Requires a command of another class directly and through cross"
  requires "reqs_tools:prep", :cross
  def twice_cross
    Reqs.journal << [:twice_cross]
  end

  desc "via_child", "Requires a command a subclass inherits"
  requires "reqs_child:fetch"
  def via_child
    Reqs.journal << [:via_child]
  end

  desc "deep_vague", "Requires a command whose requirement does not exist"
  requires :vague
  def deep_vague
    Reqs.journal << [:deep_vague]
  end

  desc "bad_args", "Maps args: to something that is not an Array"
  requires :compile, args: ->(_args, _options) { "v1" }
  def bad_args
    Reqs.journal << [:bad_args]
  end

  desc "bad_options", "Maps options: to something that is not a Hash"
  requires :compile, options: ->(_args, _options) { [:target] }
  def bad_options
    Reqs.journal << [:bad_options]
  end

  desc "loop_b", "Other half of a cycle across classes"
  requires "reqs_tools:loop_a"
  def loop_b
    Reqs.journal << [:loop_b]
  end

  desc "takes NAME", "Takes one positional argument"
  requires :fetch
  def takes(name)
    Reqs.journal << [:takes, name]
  end

  desc "retrier", "Rescues a failed requirement, then invokes the command again"
  def retrier
    begin
      invoke :strict
    rescue Thor::RequirementError
      Reqs.journal << [:rescued]
    end
    begin
      invoke :strict
    rescue Thor::RequirementError
      Reqs.journal << [:rescued_again]
    end
  end

  desc "mutator", "Maps args with a callable that mutates its input"
  requires :compile, args: ->(args, _options) { args << "mutated"; ["v1"] }
  def mutator
    Reqs.journal << [:mutator]
  end
end

class ReqsChild < ReqsPipeline
  desc "ship", "Redeclares ship without requirements"
  def ship
    Reqs.journal << [:child_ship]
  end
end

class ReqsClean < Thor
  desc "one", "Requires two"
  requires :two
  def one; end

  desc "two", "Requires a command in another class"
  requires "reqs_tools:prep"
  def two; end
end
