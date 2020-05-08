require "../spec_helper.cr"

describe Stacker::Utils do
  describe ".convert_hash" do
    it "convert YAML to internal structure" do
      inspect = <<-'TPL'
      Stacker::Pillar(@container={"foo" => Stacker::Pillar(@container={"bar" => [1, "127.0.0.1", true], "is_true" => true, "is_false" => false, "is_array" => [], "is_hash" => Stacker::Pillar(@container={}), "nested" => Stacker::Pillar(@container={"foo" => Stacker::Pillar(@container={"bar" => [1, "127.0.0.1", false], "is_true" => true, "is_false" => false, "is_array" => [], "is_hash" => Stacker::Pillar(@container={})})})})})
      TPL

      yaml = YAML.parse(File.read("spec/fixtures/input/test.yml"))
      hash = Stacker::Utils.convert_hash(yaml.as_h)
      generated_yaml = File.read("spec/fixtures/output/test.yml")

      hash.inspect.should eq(inspect)
      YAML.dump(hash).should eq(generated_yaml)
    end
  end

  describe ".yaml_to_hash" do
    it "convert YAML to internal structure" do
      inspect = <<-'TPL'
      Stacker::Pillar(@container={"foo" => Stacker::Pillar(@container={"bar" => [1, "127.0.0.1", true], "is_true" => true, "is_false" => false, "is_array" => [], "is_hash" => Stacker::Pillar(@container={}), "nested" => Stacker::Pillar(@container={"foo" => Stacker::Pillar(@container={"bar" => [1, "127.0.0.1", false], "is_true" => true, "is_false" => false, "is_array" => [], "is_hash" => Stacker::Pillar(@container={})})})})})
      TPL

      file = "spec/fixtures/input/test.yml"
      yaml = File.read(file)
      hash = Stacker::Utils.yaml_to_hash(yaml, file)
      generated_yaml = File.read("spec/fixtures/output/test.yml")

      hash.inspect.should eq(inspect)
      YAML.dump(hash).should eq(generated_yaml)
    end
  end

  describe ".deep_merge" do
    it "deep merges internal structure " do
      hash1 = load_yaml("spec/fixtures/input/deep_merge_dict1.yml")
      hash2 = load_yaml("spec/fixtures/input/deep_merge_dict2.yml")
      generated_yaml = File.read("spec/fixtures/output/deep_merge.yml")

      Stacker::Utils.deep_merge!(hash1, hash2)
      YAML.dump(hash1).should eq(generated_yaml)
    end
  end
end
