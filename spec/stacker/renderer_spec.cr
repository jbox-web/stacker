require "../spec_helper.cr"

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

  it "support log function" do
    env = create_renderer
    env.compile("spec/fixtures/log.j2", Hash(String, String).new).should eq("")
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
end
