require "../spec_helper.cr"

describe Stacker::Value do
  describe ".yaml_to_pillar" do
    it "convert YAML to internal structure" do
      inspect = <<-'TPL'
      Stacker::Value(@container={"foo" => Stacker::Value(@container={"bar" => [1, "127.0.0.1", true], "is_true" => true, "is_false" => false, "is_array" => [], "is_hash" => Stacker::Value(@container={}), "nested" => Stacker::Value(@container={"foo" => Stacker::Value(@container={"bar" => [1, "127.0.0.1", false], "is_true" => true, "is_false" => false, "is_array" => [], "is_hash" => Stacker::Value(@container={})})})})})
      TPL

      file = "spec/fixtures/merge_strategies/input/test.yml"
      yaml = File.read(file)
      hash = Stacker::Value.yaml_to_pillar(yaml)
      generated_yaml = File.read("spec/fixtures/merge_strategies/output/test.yml")

      hash.inspect.should eq(inspect)
      YAML.dump(hash).should eq(generated_yaml)
    end
  end

  describe ".convert_hash" do
    it "convert YAML to internal structure" do
      inspect = <<-'TPL'
      Stacker::Value(@container={"foo" => Stacker::Value(@container={"bar" => [1, "127.0.0.1", true], "is_true" => true, "is_false" => false, "is_array" => [], "is_hash" => Stacker::Value(@container={}), "nested" => Stacker::Value(@container={"foo" => Stacker::Value(@container={"bar" => [1, "127.0.0.1", false], "is_true" => true, "is_false" => false, "is_array" => [], "is_hash" => Stacker::Value(@container={})})})})})
      TPL

      yaml = YAML.parse(File.read("spec/fixtures/merge_strategies/input/test.yml"))
      hash = Stacker::Value.convert_hash(yaml.as_h)
      generated_yaml = File.read("spec/fixtures/merge_strategies/output/test.yml")

      hash.inspect.should eq(inspect)
      YAML.dump(hash).should eq(generated_yaml)
    end
  end

  describe ".deep_merge" do
    it "deep merges internal structure " do
      hash1 = load_yaml("spec/fixtures/merge_strategies/input/deep_merge_dict1.yml")
      hash2 = load_yaml("spec/fixtures/merge_strategies/input/deep_merge_dict2.yml")
      generated_yaml = File.read("spec/fixtures/merge_strategies/output/deep_merge.yml")

      Stacker::Value.deep_merge!(hash1, hash2)
      YAML.dump(hash1).should eq(generated_yaml)
    end

    describe "hash merging strategies" do
      context "when strategy is merge last" do
        it "should merge last hash" do
          hash1 = load_yaml("spec/fixtures/merge_strategies/input/merge_strategy_hash/merge_last_1.yml")
          hash2 = load_yaml("spec/fixtures/merge_strategies/input/merge_strategy_hash/merge_last_2.yml")
          generated_yaml = File.read("spec/fixtures/merge_strategies/output/merge_strategy_hash/merge_last.yml")

          Stacker::Value.deep_merge!(hash1, hash2)
          YAML.dump(hash1).should eq(generated_yaml)
        end
      end

      context "when strategy is merge first" do
        it "should merge first hash" do
          hash1 = load_yaml("spec/fixtures/merge_strategies/input/merge_strategy_hash/merge_first_1.yml")
          hash2 = load_yaml("spec/fixtures/merge_strategies/input/merge_strategy_hash/merge_first_2.yml")
          generated_yaml = File.read("spec/fixtures/merge_strategies/output/merge_strategy_hash/merge_first.yml")

          Stacker::Value.deep_merge!(hash1, hash2)
          YAML.dump(hash1).should eq(generated_yaml)
        end
      end

      context "when strategy is remove" do
        it "should remove hash" do
          hash1 = load_yaml("spec/fixtures/merge_strategies/input/merge_strategy_hash/remove_1.yml")
          hash2 = load_yaml("spec/fixtures/merge_strategies/input/merge_strategy_hash/remove_2.yml")
          generated_yaml = File.read("spec/fixtures/merge_strategies/output/merge_strategy_hash/remove.yml")

          Stacker::Value.deep_merge!(hash1, hash2)
          YAML.dump(hash1).should eq(generated_yaml)
        end
      end

      context "when strategy is overwrite" do
        it "should overwrite hash" do
          hash1 = load_yaml("spec/fixtures/merge_strategies/input/merge_strategy_hash/overwrite_1.yml")
          hash2 = load_yaml("spec/fixtures/merge_strategies/input/merge_strategy_hash/overwrite_2.yml")
          generated_yaml = File.read("spec/fixtures/merge_strategies/output/merge_strategy_hash/overwrite.yml")

          Stacker::Value.deep_merge!(hash1, hash2)
          YAML.dump(hash1).should eq(generated_yaml)
        end
      end
    end

    describe "array merging strategies" do
      context "when strategy is merge last" do
        it "should merge last array" do
          hash1 = load_yaml("spec/fixtures/merge_strategies/input/merge_strategy_array/merge_last_1.yml")
          hash2 = load_yaml("spec/fixtures/merge_strategies/input/merge_strategy_array/merge_last_2.yml")
          generated_yaml = File.read("spec/fixtures/merge_strategies/output/merge_strategy_array/merge_last.yml")

          Stacker::Value.deep_merge!(hash1, hash2)
          YAML.dump(hash1).should eq(generated_yaml)
        end
      end

      context "when strategy is merge first" do
        it "should merge first array" do
          hash1 = load_yaml("spec/fixtures/merge_strategies/input/merge_strategy_array/merge_first_1.yml")
          hash2 = load_yaml("spec/fixtures/merge_strategies/input/merge_strategy_array/merge_first_2.yml")
          generated_yaml = File.read("spec/fixtures/merge_strategies/output/merge_strategy_array/merge_first.yml")

          Stacker::Value.deep_merge!(hash1, hash2)
          YAML.dump(hash1).should eq(generated_yaml)
        end
      end

      context "when strategy is remove" do
        it "should remove array" do
          hash1 = load_yaml("spec/fixtures/merge_strategies/input/merge_strategy_array/remove_1.yml")
          hash2 = load_yaml("spec/fixtures/merge_strategies/input/merge_strategy_array/remove_2.yml")
          generated_yaml = File.read("spec/fixtures/merge_strategies/output/merge_strategy_array/remove.yml")

          Stacker::Value.deep_merge!(hash1, hash2)
          YAML.dump(hash1).should eq(generated_yaml)
        end
      end

      context "when strategy is overwrite" do
        it "should overwrite array" do
          hash1 = load_yaml("spec/fixtures/merge_strategies/input/merge_strategy_array/overwrite_1.yml")
          hash2 = load_yaml("spec/fixtures/merge_strategies/input/merge_strategy_array/overwrite_2.yml")
          generated_yaml = File.read("spec/fixtures/merge_strategies/output/merge_strategy_array/overwrite.yml")

          Stacker::Value.deep_merge!(hash1, hash2)
          YAML.dump(hash1).should eq(generated_yaml)
        end
      end
    end
  end
end
