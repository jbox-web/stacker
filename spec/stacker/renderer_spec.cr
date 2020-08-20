require "../spec_helper.cr"

private def s(value : Log::Severity)
  value
end

describe Stacker::Renderer do
  it "support array_push function" do
    env = create_renderer
    env.compile("spec/fixtures/array_push.j2", Hash(String, String).new).should eq("['foo', 'bar']")
  end

  it "support merge_dict function" do
    env = create_renderer
    env.compile("spec/fixtures/merge_dict.j2", Hash(String, String).new).should eq("{'foo' => {'enabled' => true}, 'bar' => {'enabled' => true}}")
  end

  it "support (deep) merge_dict function" do
    env = create_renderer
    env.compile("spec/fixtures/deep_merge_dict.j2", Hash(String, String).new).should eq("{'string' => 'b string', 'integer' => 2, 'is_true' => false, 'is_false' => true, 'old_key' => 'foo', 'hash' => {'foo' => 'bar', 'nested' => {'hash' => 'bar', 'hash1' => 'child1', 'array' => ['foo', 'bar'], 'hash2' => 'child2'}, 'bar' => 'baz'}, 'array' => ['string1', 11, true, false, 'string2', 12, false, true], 'new_key' => 'foo'}")
  end

  # See: https://github.com/crystal-lang/crystal/blob/master/spec/std/log/log_spec.cr#L147
  it "support log function" do
    backend = Log::MemoryBackend.new
    Stacker::Log.backend = backend
    env = create_renderer
    env.compile("spec/fixtures/log.j2", Hash(String, String).new).should eq("")
    entry = backend.entries.first
    entry.source.should eq("stacker")
    entry.severity.should eq(s(:info))
    entry.message.should eq("foo")
  end

  it "support traverse filter" do
    data = {"id" => "foo", "server" => {"roles" => ["php", "nginx"]}}
    env = create_renderer
    env.compile("spec/fixtures/traverse.j2", {"pillar" => data}).should eq("foo\n['php', 'nginx']")
  end

  it "support traverse filter with default value" do
    data = {"id" => "foo", "server" => {"roles" => nil}}
    env = create_renderer
    env.compile("spec/fixtures/traverse.j2", {"pillar" => data}).should eq("foo\n[]")
  end

  it "support dictsort filter" do
    data = load_yaml("spec/fixtures/input/base.yml")
    generated_data = File.read("spec/fixtures/output/dictsort_generated_data.yml").chomp
    generated_yaml = File.read("spec/fixtures/output/dictsort_generated_yaml.yml")

    env = create_renderer
    output = env.compile("spec/fixtures/dictsort.j2", {"pillar" => data})
    output.should eq(generated_data)

    yaml = YAML.parse(output)
    YAML.dump(yaml).should eq(generated_yaml)
  end
end
