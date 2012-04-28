require 'bundler/setup'
require 'nanoc3/tasks'

task :deploy do
  Dir.chdir("website") do
    system "nanoc compile"
  end

  system "mv website/output/* ."
  system "rm -r website/output"
  system "git add ."
  system "git commit -m \"Deploying on #{Date.today}\""
  system "git push origin gh-pages"
end
