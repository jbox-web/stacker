require "../spec_helper.cr"

private def config_for(root)
  <<-YAML
  ---
  doc_root: #{root}
  entrypoint: sp
  log_file: stdout
  stacks:
    default:
      - #{root}/sp/stack.cfg
  YAML
end

private FILES = {
  "sp/stack.cfg"   => "base.yml\n{{ minion_id }}.yml\n",
  "sp/base.yml"    => "base:\n  a: 1\n",
  "sp/h1.yml"      => "host:\n  b: 2\n",
  "private/s.yml"  => "secret:\n  api_key: SUPERSECRET\n",
  "../outside.yml" => "leaked: true\n",
}

describe Stacker::Runner do
  describe ".process" do
    it "should build the stack of a known host" do
      with_doc_root(FILES) do |root|
        with_config(config_for(root)) do
          result = Stacker::Runner.process("h1", "default", {} of String => String, {} of String => String, "info", "", Stacker::Processor.valid_steps)
          YAML.dump(result).should eq("---\nbase:\n  a: 1\nhost:\n  b: 2\n")
        end
      end
    end

    it "should raise when the host is unknown" do
      with_doc_root(FILES) do |root|
        with_config(config_for(root)) do
          expect_raises(Stacker::HostNotFound) do
            Stacker::Runner.process("nope", "default", {} of String => String, {} of String => String, "info", "", Stacker::Processor.valid_steps)
          end
        end
      end
    end

    it "should raise when the namespace is unknown" do
      with_doc_root(FILES) do |root|
        with_config(config_for(root)) do
          expect_raises(Stacker::NamespaceNotFound) do
            Stacker::Runner.process("h1", "nope", {} of String => String, {} of String => String, "info", "", Stacker::Processor.valid_steps)
          end
        end
      end
    end

    # The host name resolves a file path and is interpolated in the stack config
    # templates: `../` used to read any .yml file on the filesystem.
    it "should reject a host name that could escape the entrypoint" do
      with_doc_root(FILES) do |root|
        with_config(config_for(root)) do
          ["../private/s", "../../outside", "sub/h1", "..", "/etc/passwd", "h1\n", "*", ""].each do |host_name|
            expect_raises(Stacker::InvalidHostName) do
              Stacker::Runner.process(host_name, "default", {} of String => String, {} of String => String, "info", "", Stacker::Processor.valid_steps)
            end
          end
        end
      end
    end

    it "should accept the host names Salt actually uses" do
      with_doc_root(FILES) do |root|
        with_config(config_for(root)) do
          ["server1.example.net", "web-01", "web_01", "srv1"].each do |host_name|
            # Unknown hosts are fine here: the point is that the name passes validation.
            expect_raises(Stacker::HostNotFound) do
              Stacker::Runner.process(host_name, "default", {} of String => String, {} of String => String, "info", "", Stacker::Processor.valid_steps)
            end
          end
        end
      end
    end
  end
end
