---
title: Home
---

<header>
Thor is a toolkit for building powerful command-line interfaces. It is used in Bundler, Vagrant, Rails and others.
</header>

# Getting Started

A simple Thor class exposes an executable with a number of subcommands,
like `git` or `bundler`. In a Thor class, public methods become
commands.

<ruby>
class MyCLI < Thor
  desc "hello NAME", "say hello to NAME"
  def hello(name)
    puts "Hello #{name}"
  end
end
</ruby>

You can start the CLI with a call to `MyCLI.start(ARGV)`. Typically, you
would do this in an executable in the `bin` directory of your gem.

If the arguments you pass to `start` are empty, Thor will print out a
help listing for your class.

Throughout the rest of this guide, I will assume that you have a file
called `cli` in the current directory that looks like this:

<ruby>
require "thor"

class MyCLI < Thor
  # contents of the Thor class
end

MyCLI.start(ARGV)
</ruby>

Thor will automatically use the executable name in the help it generates
for a Thor class.

<plain>
$ ruby ./cli

Tasks:
  cli hello NAME   # say hello to NAME
  cli help [TASK]  # Describe available tasks or one specific task
</plain>

If you execute the hello task with a parameter, it will call your
method:

<plain>
$ ruby ./cli hello Yehuda
Hello Yehuda
</plain>

If you execute it without a parameter, Thor will automatically print a
useful error message:

<plain>
$ ruby ./cli hello
"hello" was called incorrectly. Call as "test.rb hello NAME".
</plain>

You can also use Ruby's optional arguments to make a CLI argument
optional:

<ruby>
class MyCLI < Thor
  desc "hello NAME", "say hello to NAME"
  def hello(name, from=nil)
    puts "from: #{from}" if from
    puts "Hello #{name}"
  end
end
</ruby>

When you execute it:

<plain>
$ ruby ./cli hello "Yehuda Katz"
Hello Yehuda Katz

$ ruby ./cli hello "Yehuda Katz" "Carl Lerche"
from: Carl Lerche
Hello Yehuda Katz
</plain>

This can be useful in some cases, but in most cases you will want to use
Unix-style options.

# Long Description

By default, Thor will use the short description provided to `desc` in
long usage information.

<plain>
$ ruby ./cli help hello
Usage:
  test.rb hello NAME

say hello to NAME
</plain>

In many cases, you will want to provide a longer description for use in
the longer usage instructions. In this case, you can use `long_desc` to
specify longer usage instructions.

<ruby>
class MyCLI < Thor
  desc "hello NAME", "say hello to NAME"
  long_desc <<-LONGDESC
    `cli hello` will print out a message to a person of your
    choosing.

    You can optionally specify a second parameter, which will print
    out a from message as well.

    > $ cli hello "Yehuda Katz" "Carl Lerche"

    > from: Carl Lerche
  LONGDESC
  def hello(name, from=nil)
    puts "from: #{from}" if from
    puts "Hello #{name}"
  end
end
</ruby>

By default, the long description wraps lines at the size of the
terminal and will group lines with a single line break together, just
like Markdown. You can also use the `\x5` escape sequence at the beginning
of a line to force a single hard break between lines.

<ruby>
class MyCLI < Thor
  desc "hello NAME", "say hello to NAME"
  long_desc <<-LONGDESC
    `cli hello` will print out a message to a person of your
    choosing.

    You can optionally specify a second parameter, which will print
    out a from message as well.

    > $ cli hello "Yehuda Katz" "Carl Lerche"
    \x5> from: Carl Lerche
  LONGDESC
  def hello(name, from=nil)
    puts "from: #{from}" if from
    puts "Hello #{name}"
  end
end
</ruby>

In many cases, you will want to store the long descriptions in separate
files to keep your CLI description short and readable. You can then use
`File.read` to pull in the contents of the file.

# Options and Flags

Thor makes it easy to specify options and flags as metadata about a Thor
command:

<ruby>
class MyCLI < Thor
  desc "hello NAME", "say hello to NAME"
  option :from
  def hello(name)
    puts "from: #{options[:from]}" if options[:from]
    puts "Hello #{name}"
  end
end
</ruby>

Now, your users can specify the from option as a flag:

<plain>
$ ruby ./cli hello --from "Carl Lerche" Yehuda
from: Carl Lerche
Hello Yehuda

$ ruby ./cli hello Yehuda --from "Carl Lerche"
from: Carl Lerche
Hello Yehuda

$ ruby ./cli hello Yehuda --from="Carl Lerche"
from: Carl Lerche
Hello Yehuda
</plain>

By default, options are Strings, but you can specify an alternate type
for any options:

<ruby>
class MyCLI < Thor
  option :from
  option :yell, :type => :boolean
  desc "hello NAME", "say hello to NAME"
  def hello(name)
    output = []
    output << "from: #{options[:from]}" if options[:from]
    output << "Hello #{name}"
    output = output.join("\n")
    puts options[:yell] ? output.upcase : output
  end
end
</ruby>

Now, you can make the output from your task all caps:

<plain>
$ ./cli hello --yell Yehuda --from "Carl Lerche"
FROM: CARL LERCHE
HELLO YEHUDA

$ ./cli hello Yehuda --from "Carl Lerche" --yell
FROM: CARL LERCHE
HELLO YEHUDA
</plain>

You can also specify that a particular option is `required`.

<ruby>
class MyCLI < Thor
  option :from, :required => true
  option :yell, :type => :boolean
  desc "hello NAME", "say hello to NAME"
  def hello(name)
    output = []
    output << "from: #{options[:from]}" if options[:from]
    output << "Hello #{name}"
    output = output.join("\n")
    puts options[:yell] ? output.upcase : output
  end
end
</ruby>

Now, if I try to run the command without the `required` option:

<plain>
$ ./cli hello Yehuda
No value provided for required options '--from'
</plain>

The full list of metadata you can provide for an option:

* `:desc`: A description for the option. When printing out full usage
  for a command using `cli help hello`, this description will appear
  next to the option.
* `:banner`: The short description of the option, printed out in the
  usage description. By default, this is the upcase version of the flag
  (`from=FROM`).
* `:required`: Indicates that an option is required
* `:default`: The default value of this option if it is not provided. An
  option cannot be both `:required` and have a `:default`.
* `:type`: `:string`, `:hash`, `:array`, `:numeric`, or `:boolean`
* `:aliases`: A list of aliases for this option. Typically, you would
  use aliases to provide short versions of the option.

You can use a shorthand to specify a number of options at once if you
just want to specify the type of the options. You could rewrite the
previous example as:

<ruby>
class MyCLI < Thor
  desc "hello NAME", "say hello to NAME"
  options :from => :required, :yell => :boolean
  def hello(name)
    output = []
    output << "from: #{options[:from]}" if options[:from]
    output << "Hello #{name}"
    output = output.join("\n")
    puts options[:yell] ? output.upcase : output
  end
end
</ruby>

In the shorthand, you can specify `:required` as the type, and the
option will become a required `:string`.

# Class Options

You can specify an option that should exist for the entire class by
using `class_option`. Class options take exactly the same parameters
as options for individual commands, but apply across all commands for
a class.

The `options` hash in a given task will include any class options.

<ruby>
class MyCLI < Thor
  class_option :verbose, :type => :boolean

  desc "hello NAME", "say hello to NAME"
  options :from => :required, :yell => :boolean
  def hello(name)
    puts "> saying hello" if options[:verbose]
    output = []
    output << "from: #{options[:from]}" if options[:from]
    output << "Hello #{name}"
    output = output.join("\n")
    puts options[:yell] ? output.upcase : output
    puts "> done saying hello" if options[:verbose]
  end

  desc "goodbye", "say goodbye to the world"
  def goodbye
    puts "> saying goodbye" if options[:verbose]
    puts "Goodbye World"
    puts "> done saying goodbye" if options[:verbose]
  end
end
</ruby>


# Subcommands

As your CLI becomes more complex, you might want to be able to specify a
command that points at its own set of subcommands. One example of this
is the `git remote` command, which exposes `add`, `rename`, `rm`,
`prune`, `set-head`, and so on.

In Thor, you can achieve this easily by creating a new Thor class to
represent the subcommand, and point to it from the parent class. Let's
take a look at how you would implement `git remote`. The example is
intentionally simplified.

<ruby>
module GitCLI
  class Remote < Thor
    desc "add <name> <url>", "Adds a remote named <name> for the repository at <url>"
    long_desc <<-LONGDESC
      Adds a remote named <name> for the repository at <url>. The command git fetch <name> can then be used to create and update
      remote-tracking branches <name>/<branch>.

      With -f option, git fetch <name> is run immediately after the remote information is set up.

      With --tags option, git fetch <name> imports every tag from the remote repository.

      With --no-tags option, git fetch <name> does not import tags from the remote repository.

      With -t <branch> option, instead of the default glob refspec for the remote to track all branches under $GIT_DIR/remotes/<name>/, a
      refspec to track only <branch> is created. You can give more than one -t <branch> to track multiple branches without grabbing all
      branches.

      With -m <master> option, $GIT_DIR/remotes/<name>/HEAD is set up to point at remote's <master> branch. See also the set-head
      command.

      When a fetch mirror is created with --mirror=fetch, the refs will not be stored in the refs/remotes/ namespace, but rather
      everything in refs/ on the remote will be directly mirrored into refs/ in the local repository. This option only makes sense in
      bare repositories, because a fetch would overwrite any local commits.

      When a push mirror is created with --mirror=push, then git push will always behave as if --mirror was passed.
    LONGDESC
    option :t, :banner => "<branch>"
    option :m, :banner => "<master>"
    options :f => :boolean, :tags => :boolean, :mirror => :string
    def add(name, url)
      # implement git remote add
    end

    desc "rename <old> <new>", "Rename the remote named <old> to <new>"
    def rename(old, new)
    end
  end

  class Git < Thor
    desc "fetch <repository> [<refspec>...]", "Download objects and refs from another repository"
    options :all => :boolean, :multiple => :boolean
    option :append, :type => :boolean, :aliases => :a
    def fetch(respository, *refspec)
      # implement git fetch here
    end

    desc "remote SUBCOMMAND ...ARGS", "manage set of tracked repositories"
    subcommand "remote", Remote
  end
end
</ruby>

You can access the options from the parent command in a subcommand using
the `parent_options` accessor.

<header>
  Do you use Thor? Help support the people who made and maintain it!

<div class="footer">
  <div class="person">
    <p><a href="http://www.twitter.com/wycats">Yehuda Katz</a></p>
      <div class="gratipay">
      <script data-gratipay-username="wycats"
          src="//grtp.co/v1.js"></script>
      </div>
  </div>

  <div class="person">
    <p><a href="http://www.twitter.com/sferik">Erik Michaels-Ober</a></p>
      <div class="gratipay">
        <script data-gratipay-username="sferik"
          src="//grtp.co/v1.js"></script>
      </div>
  </div>
</div>
</header>
