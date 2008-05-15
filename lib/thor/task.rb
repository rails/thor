class Thor
  class Task < Struct.new(:meth, :description, :usage, :opts, :klass)
    def with_klass(klass)
      new = self.dup
      new.klass = klass
      new
    end

    def formatted_opts
      return "" if opts.nil?
      opts.map do |opt, val|
        if val == true || val == "BOOLEAN"
          "[#{opt}]"
        elsif val == "REQUIRED"
          opt + "=" + opt.gsub(/\-/, "").upcase
        elsif val == "OPTIONAL"
          "[" + opt + "=" + opt.gsub(/\-/, "").upcase + "]"
        end
      end.join(" ")
    end

    def formatted_usage
      usage + (opts ? " " + formatted_opts : "")
    end
  end
end
