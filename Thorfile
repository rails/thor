require 'rubygems'
require 'rake/gempackagetask'
require 'rubygems/specification'
require 'spec/rake/spectask'
require 'date'

GEM = "thor"
GEM_VERSION = "0.9.1"
AUTHOR = "Yehuda Katz"
EMAIL = "wycats@gmail.com"
HOMEPAGE = "http://yehudakatz.com"
SUMMARY = "A gem that maps options to a class"

spec = Gem::Specification.new do |s|
  s.name = GEM
  s.version = GEM_VERSION
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  s.extra_rdoc_files = ["README.markdown", "LICENSE"]
  s.summary = SUMMARY
  s.description = s.summary
  s.author = AUTHOR
  s.email = EMAIL
  s.homepage = HOMEPAGE
    
  s.require_path = 'lib'
  s.autorequire = GEM
  s.bindir = "bin"
  s.executables = %w( thor )
  s.files = %w(LICENSE README.markdown Rakefile) + Dir.glob("{bin,lib,specs}/**/*")
end

require "spec"

module Spec
  module Rake
    class SpecTask
      def make_thortask(klass)
        spec_name = name
        lib_path = @lib_path

        # Make these available in the closure
        spec_file_list = self.spec_file_list
        ruby_opts = self.ruby_opts
        rcov = self.rcov
        warning = self.warning
        rcov_option_list = self.rcov_option_list
        rcov_dir = self.rcov_dir
        spec_option_list = self.spec_option_list
        out = self.out
        failure_message = self.failure_message
        fail_on_error = self.fail_on_error
    
        lib_path = libs.join(File::PATH_SEPARATOR)
        actual_name = Hash === name ? name.keys.first : name
    
        klass.class_eval do
      
          desc "#{spec_name}", "run specs"
          define_method spec_name do
            unless spec_file_list.empty?
              # ruby [ruby_opts] -Ilib -S rcov [rcov_opts] bin/spec -- examples [spec_opts]
              # or
              # ruby [ruby_opts] -Ilib bin/spec examples [spec_opts]
              cmd = "ruby "

              rb_opts = ruby_opts.clone
              rb_opts << "-S rcov" if rcov
              rb_opts << "-w" if warning
              cmd << rb_opts.join(" ")
              cmd << " "
              cmd << rcov_option_list
              cmd << %[ -o "#{rcov_dir}" ] if rcov
              cmd << %Q|"#{`which spec`.chomp}"|
              cmd << " "
              cmd << "-- " if rcov
              cmd << spec_file_list.collect { |fn| %["#{fn}"] }.join(' ')
              cmd << " "
              cmd << spec_option_list
              if out
                cmd << " "
                cmd << %Q| > "#{out}"|
                STDERR.puts "The Spec::Rake::SpecTask#out attribute is DEPRECATED and will be removed in a future version. Use --format FORMAT:WHERE instead."
              end
              if verbose
                puts cmd
              end
              unless system(cmd)
                STDERR.puts failure_message if failure_message
                raise("Command #{cmd} failed") if fail_on_error
              end
            end
          end
      
        end
      end
    end
  end
end

Spec::Thor = Spec::Rake

class Meta < Thor
  Spec::Rake::SpecTask.new do |t|
    t.libs << "spec"
    t.spec_files = FileList["spec/**/*_spec.rb"]
    t.spec_opts << "-fs --color"
  end.make_thortask(self)
end