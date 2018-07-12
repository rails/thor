describe "when the Thor class's exit_with_failure? method returns true" do
  def thor_command(command)
    gem_dir= File.expand_path("#{File.dirname(__FILE__)}/..")
    lib_path= "#{gem_dir}/lib"
    script_path= "#{gem_dir}/spec/fixtures/exit_status.thor"
    ruby_lib= ENV['RUBYLIB'].nil? ? lib_path : "#{lib_path}:#{ENV['RUBYLIB']}"

    full_command= "ruby #{script_path} #{command}"
    r,w= IO.pipe
    pid= spawn({'RUBYLIB' => ruby_lib},
               full_command,
               {:out => w, :err => [:child, :out]})
    w.close

    junk, exit_status= Process.wait2(pid)
    junk= r.read
    r.close

    exit_status.exitstatus
  end

  it "a command that raises a Thor::Error exits with a status of 1" do
    expect(thor_command("error")).to eq(1)
  end

  it "a command that does not raise a Thor::Error exits with a status of 0" do
    expect(thor_command("ok")).to eq(0)
  end
end if RUBY_VERSION > "1.8.7"
