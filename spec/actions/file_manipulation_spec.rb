require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

class Application; end

describe Thor::Actions do
  def runner(options={})
    @runner ||= MyCounter.new([1], options, { :destination_root => destination_root })
  end

  def action(*args, &block)
    capture(:stdout){ runner.send(*args, &block) }
  end

  def exists_and_identical?(source, destination)
   destination = File.join(destination_root, destination)
   File.exists?(destination).must be_true

   source = File.join(source_root, source)
   FileUtils.must be_identical(source, destination)
  end

  def file
    File.join(destination_root, "foo")
  end

  before(:each) do
    ::FileUtils.rm_rf(destination_root)
  end

  describe "#chmod" do
    it "executes the command given" do
      FileUtils.should_receive(:chmod_R).with(0755, file)
      action :chmod, "foo", 0755
    end

    it "does not execute the command if pretending given" do
      FileUtils.should_not_receive(:chmod_R)
      runner(:pretend => true)
      action :chmod, "foo", 0755
    end

    it "logs status" do
      FileUtils.should_receive(:chmod_R).with(0755, file)
      action(:chmod, "foo", 0755).must == "       chmod  foo\n"
    end

    it "does not log status if required" do
      FileUtils.should_receive(:chmod_R).with(0755, file)
      action(:chmod, "foo", 0755, :verbose => false).must be_empty
    end
  end

  describe "#copy_file" do
    it "copies file from source to default destination" do
      action :copy_file, "task.thor"
      exists_and_identical?("task.thor", "task.thor")
    end

    it "copies file from source to the specified destination" do
      action :copy_file, "task.thor", "foo.thor"
      exists_and_identical?("task.thor", "foo.thor")
    end

    it "copies file from the source relative to the current path" do
      runner.inside("doc") do
        action :copy_file, "README"
      end
      exists_and_identical?("doc/README", "doc/README")
    end

    it "logs status" do
      action(:copy_file, "task.thor").must == "      create  task.thor\n"
    end

    it "accepts a block to change output" do
      action :copy_file, "task.thor" do |content|
        "OMG" + content
      end
      File.read(File.join(destination_root, "task.thor")).must =~ /^OMG/
    end
  end

  describe "#get" do
    it "copies file from source to the specified destination" do
      action :get, "doc/README", "docs/README"
      exists_and_identical?("doc/README", "docs/README")
    end

    it "uses just the source basename as destination if none is specified" do
      action :get, "doc/README"
      exists_and_identical?("doc/README", "README")
    end

    it "allows the destination to be set as a block result" do
      action(:get, "doc/README"){ |c| "docs/README" }
      exists_and_identical?("doc/README", "docs/README")
    end

    it "yields file content to a block" do
      action :get, "doc/README" do |content|
        content.must == "__start__\nREADME\n__end__\n"
      end
    end

    it "logs status" do
      action(:get, "doc/README", "docs/README").must == "      create  docs/README\n"
    end

    it "accepts http remote sources" do
      body = "__start__\nHTTPFILE\n__end__\n"
      FakeWeb.register_uri(:get, 'http://example.com/file.txt', :body => body)
      action :get, 'http://example.com/file.txt' do |content|
        content.must == body
      end
      FakeWeb.clean_registry
    end
  end

  describe "#template" do
    it "evaluates the template given as source" do
      runner.instance_variable_set("@klass", "Config")
      action :template, "doc/config.rb"

      file = File.join(destination_root, "doc/config.rb")
      File.read(file).must == "class Config; end\n"
    end

    it "copies the template to the specified destination" do
      action :template, "doc/config.rb", "doc/configuration.rb"
      file = File.join(destination_root, "doc/configuration.rb")
      File.exists?(file).must be_true
    end

    it "converts enconded instructions" do
      runner.should_receive(:file_name).and_return("rdoc")
      action :template, "doc/%file_name%.rb.tt"
      file = File.join(destination_root, "doc/rdoc.rb.tt")
      File.exists?(file).must be_true
    end

    it "logs status" do
      capture(:stdout){ runner.template("doc/config.rb") }.must == "      create  doc/config.rb\n"
    end

    it "accepts a block to change output" do
      action :template, "doc/config.rb" do |content|
        "OMG" + content
      end
      File.read(File.join(destination_root, "doc/config.rb")).must =~ /^OMG/
    end
  end

  describe "when changing existent files" do
    before(:each) do
      ::FileUtils.cp_r(source_root, destination_root)
    end

    def file
      File.join(destination_root, "doc", "README")
    end

    describe "#remove_file" do
      it "removes the file given" do
        action :remove_file, "doc/README"
        File.exists?(file).must be_false
      end

      it "removes directories too" do
        action :remove_dir, "doc"
        File.exists?(File.join(destination_root, "doc")).must be_false
      end

      it "does not remove if pretending" do
        runner(:pretend => true)
        action :remove_file, "doc/README"
        File.exists?(file).must be_true
      end

      it "logs status" do
        action(:remove_file, "doc/README").must == "      remove  doc/README\n"
      end

      it "does not log status if required" do
        action(:remove_file, "doc/README", :verbose => false).must be_empty
      end
    end

    describe "#gsub_file" do
      it "replaces the content in the file" do
        action :gsub_file, "doc/README", "__start__", "START"
        File.binread(file).must == "START\nREADME\n__end__\n"
      end

      it "does not replace if pretending" do
        runner(:pretend => true)
        action :gsub_file, "doc/README", "__start__", "START"
        File.binread(file).must == "__start__\nREADME\n__end__\n"
      end

      it "accepts a block" do
        action(:gsub_file, "doc/README", "__start__"){ |match| match.gsub('__', '').upcase  }
        File.binread(file).must == "START\nREADME\n__end__\n"
      end

      it "logs status" do
        action(:gsub_file, "doc/README", "__start__", "START").must == "        gsub  doc/README\n"
      end

      it "does not log status if required" do
        action(:gsub_file, file, "__", :verbose => false){ |match| match * 2 }.must be_empty
      end
    end

    describe "#append_file" do
      it "appends content to the file" do
        action :append_file, "doc/README", "END\n"
        File.binread(file).must == "__start__\nREADME\n__end__\nEND\n"
      end

      it "accepts a block" do
        action(:append_file, "doc/README"){ "END\n" }
        File.binread(file).must == "__start__\nREADME\n__end__\nEND\n"
      end

      it "logs status" do
        action(:append_file, "doc/README", "END").must == "      append  doc/README\n"
      end
    end

    describe "#prepend_file" do
      it "prepends content to the file" do
        action :prepend_file, "doc/README", "START\n"
        File.binread(file).must == "START\n__start__\nREADME\n__end__\n"
      end

      it "accepts a block" do
        action(:prepend_file, "doc/README"){ "START\n" }
        File.binread(file).must == "START\n__start__\nREADME\n__end__\n"
      end

      it "logs status" do
        action(:prepend_file, "doc/README", "START").must == "     prepend  doc/README\n"
      end
    end

    describe "#inject_into_class" do
      def file
        File.join(destination_root, "application.rb")
      end

      it "appends content to a class" do
        action :inject_into_class, "application.rb", Application, "  filter_parameters :password\n"
        File.binread(file).must == "class Application < Base\n  filter_parameters :password\nend\n"
      end

      it "accepts a block" do
        action(:inject_into_class, "application.rb", Application){ "  filter_parameters :password\n" }
        File.binread(file).must == "class Application < Base\n  filter_parameters :password\nend\n"
      end

      it "logs status" do
        action(:inject_into_class, "application.rb", Application, "  filter_parameters :password\n").must == "      inject  application.rb\n"
      end

      it "does not append if class name does not match" do
        action :inject_into_class, "application.rb", "App", "  filter_parameters :password\n"
        File.binread(file).must == "class Application < Base\nend\n"
      end
    end
  end
end
