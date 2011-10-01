Feature: Thor::Group#class_option understands one-letter alias
  In order test #class_option parsing rules 
  As a Thor user
  I want to test a thor standalone app 
  using Thor::Group class with class_option being set

  Background: One-letter option alias
    Given a file named "example.rb" with:
      """ruby
      #!/usr/bin/env ruby

      require 'thor'
      require 'thor/group'

      module App
        class Zoo < Thor::Group
          class_option :who,
            :type => :string,
            :aliases => "-w",
            :default => "zebra"
          def animal
            p options[:who]
          end
        end

        class Boss < Thor
          register Zoo, :zoo, "zoo", "something"

          default_task :zoo
        end
      end

      App::Boss.start
      """
      And I run `chmod +x example.rb`

  Scenario: Simple stupid example just runs
    When I run `./example.rb`
    Then the exit status should be 0

  Scenario Outline: Simple stupid example shows help
    When I run `./example.rb <option>`
    Then the output should contain:
    """
    example.rb zoo          # something
    """

    Examples:
      | option |
      | -h     |
      | --help |
      | help   |

  Scenario Outline: it runs zoo task with different options
    When I run `./example.rb zoo <option> <value>`
    Then the output should contain:
    """
    "<word>"
    """

    Examples:
      | option | value | word  |
      |        |       | zebra |
      | --who  |       | zebra |
      | -w     |       | zebra |
      | --who  | wolf  | wolf  |
      | -w     | wolf  | wolf  |

