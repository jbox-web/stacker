require "../spec_helper.cr"

private def s(value : Log::Severity)
  value
end

describe Stacker::Renderer do
  describe "functions" do
    describe "array_push" do
      it "support array_push function" do
        renderer = create_renderer
        renderer.compile("spec/fixtures/functions/array_push.j2", Hash(String, String).new).should eq("['foo', 'bar']")
      end
    end

    describe "log" do
      # See: https://github.com/crystal-lang/crystal/blob/master/spec/std/log/log_spec.cr#L147
      it "support log function" do
        backend = Log::MemoryBackend.new
        Stacker::Renderer::Log.backend = backend
        renderer = create_renderer
        renderer.compile("spec/fixtures/functions/log.j2", Hash(String, String).new).should eq("")
        entry = backend.entries.first
        entry.source.should eq("renderer")
        entry.severity.should eq(s(:info))
        entry.message.should eq("foo")
      end
    end

    describe "merge_dict" do
      it "support merge_dict function" do
        renderer = create_renderer
        renderer.compile("spec/fixtures/functions/merge_dict.j2", Hash(String, String).new).should eq("{'foo' => {'enabled' => true}, 'bar' => {'enabled' => true}}")
      end

      it "support (deep) merge_dict function" do
        renderer = create_renderer
        renderer.compile("spec/fixtures/functions/deep_merge_dict.j2", Hash(String, String).new).should eq("{'string' => 'b string', 'integer' => 2, 'is_true' => false, 'is_false' => true, 'old_key' => 'foo', 'hash' => {'foo' => 'bar', 'nested' => {'hash' => 'bar', 'hash1' => 'child1', 'array' => ['foo', 'bar'], 'hash2' => 'child2'}, 'bar' => 'baz'}, 'array' => ['string1', 11, true, false, 'string2', 12, false, true], 'new_key' => 'foo'}")
      end
    end
  end

  describe "filters" do
    describe "json" do
      it "support json filter" do
        renderer = create_renderer
        output = renderer.compile("spec/fixtures/filters/json.j2", Hash(String, String).new)
        output.should eq("{\n  \"foo\": [\n    \"a\",\n    \"a\",\n    \"a\"\n  ],\n  \"bar\": 1,\n  \"true\": true,\n  \"false\": false\n}")
      end
    end

    describe "traverse" do
      it "support traverse filter" do
        data = {"id" => "foo", "server" => {"roles" => ["php", "nginx"]}}
        renderer = create_renderer
        renderer.compile("spec/fixtures/filters/traverse.j2", {"pillar" => data}).should eq("foo\n['php', 'nginx']")
      end

      it "support traverse filter with default value: nil" do
        data = {"id" => "foo", "server" => {"foo" => "bar"}}
        renderer = create_renderer
        renderer.compile("spec/fixtures/filters/traverse/default_nil_1.j2", {"pillar" => data}).should eq("null")
      end

      it "support traverse filter with default value: nil" do
        data = {"id" => "foo", "server" => {"foo" => "bar"}}
        renderer = create_renderer
        renderer.compile("spec/fixtures/filters/traverse/default_nil_2.j2", {"pillar" => data}).should eq("null")
      end

      it "support traverse filter with default value: true" do
        data = {"id" => "foo", "server" => {"roles" => nil}}
        renderer = create_renderer
        renderer.compile("spec/fixtures/filters/traverse/default_true.j2", {"pillar" => data}).should eq("true")
      end

      it "support traverse filter with default value: false" do
        data = {"id" => "foo", "server" => {"roles" => nil}}
        renderer = create_renderer
        renderer.compile("spec/fixtures/filters/traverse/default_false.j2", {"pillar" => data}).should eq("false")
      end

      it "support traverse filter with default value: []" do
        data = {"id" => "foo", "server" => {"roles" => nil}}
        renderer = create_renderer
        renderer.compile("spec/fixtures/filters/traverse/default_array_empty.j2", {"pillar" => data}).should eq("[]")
      end

      it "support traverse filter with default value: {}" do
        data = {"id" => "foo", "server" => {"roles" => nil}}
        renderer = create_renderer
        renderer.compile("spec/fixtures/filters/traverse/default_hash_empty.j2", {"pillar" => data}).should eq("{}")
      end

      it "support traverse filter with default value: ''" do
        data = {"id" => "foo", "server" => {"roles" => nil}}
        renderer = create_renderer
        renderer.compile("spec/fixtures/filters/traverse/default_string_empty.j2", {"pillar" => data}).should eq("\"\"")
      end

      it "support traverse filter with default value: 'true'" do
        data = {"id" => "foo", "server" => {"roles" => nil}}
        renderer = create_renderer
        renderer.compile("spec/fixtures/filters/traverse/default_string_true.j2", {"pillar" => data}).should eq("\"true\"")
      end

      it "support traverse filter with default value: 'false'" do
        data = {"id" => "foo", "server" => {"roles" => nil}}
        renderer = create_renderer
        renderer.compile("spec/fixtures/filters/traverse/default_string_false.j2", {"pillar" => data}).should eq("\"false\"")
      end

      it "support traverse filter with default value when traversal path doesn't exist (1)" do
        backend = Log::MemoryBackend.new
        Stacker::Renderer::Log.backend = backend
        Stacker::Renderer::Log.level = ::Log::Severity::Debug
        data = {"id" => "foo"}
        renderer = create_renderer
        renderer.compile("spec/fixtures/filters/traverse/traversal_path_inexistent_1.j2", {"pillar" => data}).should eq("\"\"")
        entry = backend.entries.first
        entry.source.should eq("renderer")
        entry.severity.should eq(s(:debug))
        entry.message.should eq("Attribute 'server:roles' not found in traversal path")
      end

      it "support traverse filter with default value when traversal path doesn't exist (2)" do
        data = {"id" => "foo", "server" => {"foo" => "bar"}}
        renderer = create_renderer
        renderer.compile("spec/fixtures/filters/traverse/traversal_path_inexistent_2.j2", {"pillar" => data}).should eq("\"\"")
      end
    end

    describe "unique" do
      it "support unique filter" do
        renderer = create_renderer
        output = renderer.compile("spec/fixtures/filters/unique.j2", Hash(String, String).new)
        output.should eq("['a']")
      end
    end

    describe "dictsort" do
      it "support dictsort filter" do
        data = load_yaml("spec/fixtures/filters/dictsort/base.yml")
        generated_data = File.read("spec/fixtures/filters/dictsort/dictsort_generated_data.yml").chomp
        generated_yaml = File.read("spec/fixtures/filters/dictsort/dictsort_generated_yaml.yml")

        renderer = create_renderer
        output = renderer.compile("spec/fixtures/filters/dictsort.j2", {"pillar" => data})
        output.should eq(generated_data)

        yaml = YAML.parse(output)
        YAML.dump(yaml).should eq(generated_yaml)
      end
    end
  end
end
