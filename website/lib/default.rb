# All files in the 'lib' directory will be loaded
# before nanoc starts compiling.

require "kramdown"

module Kramdown
  module Parser
    class Kramdown
      unless defined?(RUBY_START)
        RUBY_START = /^!ruby!/

        def parse_ruby_code
          data = @src.scan(self.class::CODEBLOCK_MATCH)
          data.gsub!(/\n( {0,3}\S)/, ' \\1')
          data.gsub!(INDENT, '')
          result = Uv.parse(data, "xhtml", "ruby", false, "sunburst")
          @tree.children << new_block_el(:codeblock, result)
        end
        define_parser(:ruby_code, RUBY_START)
      end
    end
  end
end
