module DiffLines

  protected
  def show_diff_common(destination, content) #:nodoc:
    if diff_lcs_loaded? && ENV['THOR_DIFF'].nil? && ENV['RAILS_DIFF'].nil?
      actual  = File.binread(destination).to_s.split("\n")
      content = content.to_s.split("\n")

      Diff::LCS.sdiff(actual, content).each do |diff|
        output_diff_line(diff)
      end
    else
      super
    end
  end

  def output_diff_line_common(diff) #:nodoc:
    case diff.action
    when '-'
      say "- #{diff.old_element.chomp}", :red, true
    when '+'
      say "+ #{diff.new_element.chomp}", :green, true
    when '!'
      say "- #{diff.old_element.chomp}", :red, true
      say "+ #{diff.new_element.chomp}", :green, true
    else
      say "  #{diff.old_element.chomp}", nil, true
    end
  end

  def diff_lcs_loaded_common? #:nodoc:
    return true  if defined?(Diff::LCS)
    return @diff_lcs_loaded unless @diff_lcs_loaded.nil?

    @diff_lcs_loaded = begin
      require 'diff/lcs'
      true
    rescue LoadError
      false
    end
  end

end
