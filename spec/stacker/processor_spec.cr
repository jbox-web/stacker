require "../spec_helper.cr"

describe Stacker::Processor do
  describe "#run" do
    it "should returns the processed data" do
      stack = ["spec/dummy/server-pillars/stack1.cfg"]
      renderer = create_renderer(doc_root: "spec/dummy", entrypoint: "server-pillars")
      processor = Stacker::Processor.new(renderer, stack)

      host_name = "server1.example.net"
      grains = {} of String => String
      pillar = {} of String => String
      namespace = ""
      path = ""
      steps = [] of String

      generated_yaml = File.read("spec/fixtures/processor/result.yml")
      stack = processor.run(host_name, grains, pillar, namespace, path, steps)

      YAML.dump(stack).should eq(generated_yaml)
    end

    # A broken stack config file used to render as an empty string, which produced an
    # empty stack indistinguishable from a legitimately empty one.
    it "should raise when the stack config file cannot be rendered" do
      files = {
        "sp/stack.cfg" => "base.yml\n{{ minion_id | nosuchfilter }}.yml\n",
        "sp/base.yml"  => "base:\n  a: 1\n",
        "sp/h1.yml"    => "host:\n  b: 2\n",
      }

      with_doc_root(files) do |root|
        expect_raises(Stacker::RenderError, /stack\.cfg/) do
          build_stack(root, "h1")
        end
      end
    end

    # A broken pillar file used to be skipped silently, delivering a partial stack.
    it "should raise when a pillar file cannot be rendered" do
      files = {
        "sp/stack.cfg" => "base.yml\n{{ minion_id }}.yml\n",
        "sp/base.yml"  => "base:\n  a: 1\n",
        "sp/h1.yml"    => "host:\n  b: {{ nope | nosuchfilter }}\n",
      }

      with_doc_root(files) do |root|
        expect_raises(Stacker::RenderError, /h1\.yml/) do
          build_stack(root, "h1")
        end
      end
    end

    it "should raise when a pillar file contains invalid YAML" do
      files = {
        "sp/stack.cfg" => "base.yml\n{{ minion_id }}.yml\n",
        "sp/base.yml"  => "base:\n  a: 1\n",
        "sp/h1.yml"    => "a:\n  - x\n b: [\n",
      }

      with_doc_root(files) do |root|
        expect_raises(Stacker::PillarError, /h1\.yml/) do
          build_stack(root, "h1")
        end
      end
    end

    # `Value.from_yaml` casts to a Hash: a sequence or a scalar at the root used to
    # raise an unrescued TypeCastError.
    it "should raise when a pillar file does not hold a YAML mapping" do
      files = {
        "sp/stack.cfg" => "base.yml\n{{ minion_id }}.yml\n",
        "sp/base.yml"  => "base:\n  a: 1\n",
        "sp/h1.yml"    => "- a\n- b\n",
      }

      with_doc_root(files) do |root|
        expect_raises(Stacker::PillarError, /h1\.yml/) do
          build_stack(root, "h1")
        end
      end
    end

    it "should accept a pillar file rendering to an empty document" do
      files = {
        "sp/stack.cfg" => "base.yml\n{{ minion_id }}.yml\n",
        "sp/base.yml"  => "base:\n  a: 1\n",
        "sp/h1.yml"    => "{# nothing to declare #}\n",
      }

      with_doc_root(files) do |root|
        YAML.dump(build_stack(root, "h1")).should eq("---\nbase:\n  a: 1\n")
      end
    end

    # `__: overwrite` at the root of a file used to drop the whole file.
    it "should apply a root level overwrite strategy" do
      files = {
        "sp/stack.cfg" => "base.yml\n{{ minion_id }}.yml\n",
        "sp/base.yml"  => "base:\n  a: 1\n",
        "sp/h1.yml"    => "__: overwrite\nhost:\n  b: 2\n",
      }

      with_doc_root(files) do |root|
        YAML.dump(build_stack(root, "h1")).should eq("---\nhost:\n  b: 2\n")
      end
    end
  end

  describe "log verbosity" do
    # The verbosity used to live on a global constant mutated for the duration of a
    # request, so a concurrent request could flip another one's level mid-flight.
    it "should keep the requested verbosity local to each processor" do
      files = {
        "sp/stack.cfg" => "base.yml\n",
        "sp/base.yml"  => "base:\n  secret: TOPSECRET\n",
      }

      with_doc_root(files) do |root|
        verbose_backend = Log::MemoryBackend.new
        quiet_backend = Log::MemoryBackend.new

        context = Stacker::Context.new(root)
        verbose = Stacker::Processor.new(
          Stacker::Renderer.new(context, "sp", Stacker::Logger.for("renderer", "trace", verbose_backend)),
          [File.join(root, "sp/stack.cfg")],
          Stacker::Logger.for("processor", "trace", verbose_backend)
        )
        quiet = Stacker::Processor.new(
          Stacker::Renderer.new(context, "sp", Stacker::Logger.for("renderer", "info", quiet_backend)),
          [File.join(root, "sp/stack.cfg")],
          Stacker::Logger.for("processor", "info", quiet_backend)
        )

        args = {"h1", {} of String => String, {} of String => String, "default", "", Stacker::Processor.valid_steps}
        verbose.run(*args)
        quiet.run(*args)
        verbose.run(*args)

        verbose_backend.entries.count(&.message.includes?("TOPSECRET")).should be > 0
        quiet_backend.entries.count(&.message.includes?("TOPSECRET")).should eq(0)
      end
    end
  end
end
