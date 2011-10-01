Feature: Thor::Group#class_option ignores one-dash-multi-letter alias
  In order to test #class_option parsing rules 
  As a Thor user
  I want to test a thor standalone app 
  using Thor::Group class with class_option being set

  Background: Two-letter option alias
    Given a file named "example.rb" with:
      """ruby
      #!/usr/bin/env ruby

      require 'thor'
      require 'thor/group'

      module App
        class Zoo < Thor::Group
          class_option :who,
            :type => :string,
            :aliases => "-wh",       # NB
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
      | -wh    |       | zebra |
      | --who  | wolf  | wolf  |
      | -wh    | wolf  | zebra |

