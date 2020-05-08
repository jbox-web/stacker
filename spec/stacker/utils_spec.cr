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

    describe "hash merging strategies" do
      context "when strategy is merge last" do
        it "should merge last hash" do
          hash1 = load_yaml("spec/fixtures/input/merge_strategy_hash/merge_last_1.yml")
          hash2 = load_yaml("spec/fixtures/input/merge_strategy_hash/merge_last_2.yml")
          generated_yaml = File.read("spec/fixtures/output/merge_strategy_hash/merge_last.yml")

          Stacker::Utils.deep_merge!(hash1, hash2)
          YAML.dump(hash1).should eq(generated_yaml)
        end
      end

      context "when strategy is merge first" do
        it "should merge first hash" do
          hash1 = load_yaml("spec/fixtures/input/merge_strategy_hash/merge_first_1.yml")
          hash2 = load_yaml("spec/fixtures/input/merge_strategy_hash/merge_first_2.yml")
          generated_yaml = File.read("spec/fixtures/output/merge_strategy_hash/merge_first.yml")

          Stacker::Utils.deep_merge!(hash1, hash2)
          YAML.dump(hash1).should eq(generated_yaml)
        end
      end

      context "when strategy is remove" do
        it "should remove hash" do
          hash1 = load_yaml("spec/fixtures/input/merge_strategy_hash/remove_1.yml")
          hash2 = load_yaml("spec/fixtures/input/merge_strategy_hash/remove_2.yml")
          generated_yaml = File.read("spec/fixtures/output/merge_strategy_hash/remove.yml")

          Stacker::Utils.deep_merge!(hash1, hash2)
          YAML.dump(hash1).should eq(generated_yaml)
        end
      end

      context "when strategy is overwrite" do
        it "should overwrite hash" do
          hash1 = load_yaml("spec/fixtures/input/merge_strategy_hash/overwrite_1.yml")
          hash2 = load_yaml("spec/fixtures/input/merge_strategy_hash/overwrite_2.yml")
          generated_yaml = File.read("spec/fixtures/output/merge_strategy_hash/overwrite.yml")

          Stacker::Utils.deep_merge!(hash1, hash2)
          YAML.dump(hash1).should eq(generated_yaml)
        end
      end
    end

    describe "array merging strategies" do
      context "when strategy is merge last" do
        it "should merge last array" do
          hash1 = load_yaml("spec/fixtures/input/merge_strategy_array/merge_last_1.yml")
          hash2 = load_yaml("spec/fixtures/input/merge_strategy_array/merge_last_2.yml")
          generated_yaml = File.read("spec/fixtures/output/merge_strategy_array/merge_last.yml")

          Stacker::Utils.deep_merge!(hash1, hash2)
          YAML.dump(hash1).should eq(generated_yaml)
        end
      end

      context "when strategy is merge first" do
        it "should merge first array" do
          hash1 = load_yaml("spec/fixtures/input/merge_strategy_array/merge_first_1.yml")
          hash2 = load_yaml("spec/fixtures/input/merge_strategy_array/merge_first_2.yml")
          generated_yaml = File.read("spec/fixtures/output/merge_strategy_array/merge_first.yml")

          Stacker::Utils.deep_merge!(hash1, hash2)
          YAML.dump(hash1).should eq(generated_yaml)
        end
      end

      context "when strategy is remove" do
        it "should remove array" do
          hash1 = load_yaml("spec/fixtures/input/merge_strategy_array/remove_1.yml")
          hash2 = load_yaml("spec/fixtures/input/merge_strategy_array/remove_2.yml")
          generated_yaml = File.read("spec/fixtures/output/merge_strategy_array/remove.yml")

          Stacker::Utils.deep_merge!(hash1, hash2)
          YAML.dump(hash1).should eq(generated_yaml)
        end
      end

      context "when strategy is overwrite" do
        it "should overwrite array" do
          hash1 = load_yaml("spec/fixtures/input/merge_strategy_array/overwrite_1.yml")
          hash2 = load_yaml("spec/fixtures/input/merge_strategy_array/overwrite_2.yml")
          generated_yaml = File.read("spec/fixtures/output/merge_strategy_array/overwrite.yml")

          Stacker::Utils.deep_merge!(hash1, hash2)
          YAML.dump(hash1).should eq(generated_yaml)
        end
      end
    end
  end
end
