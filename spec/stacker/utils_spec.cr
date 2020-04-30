require "../spec_helper.cr"

describe Stacker::Utils do
  describe ".convert_hash" do
    it "convert YAML to internal structure" do
      inspect = <<-'TPL'
      Stacker::Pillar(@container={"foo" => Stacker::Pillar(@container={"bar" => [1, "127.0.0.1", true], "is_true" => true, "is_false" => false, "is_array" => [], "is_hash" => Stacker::Pillar(@container={}), "nested" => Stacker::Pillar(@container={"foo" => Stacker::Pillar(@container={"bar" => [1, "127.0.0.1", false], "is_true" => true, "is_false" => false, "is_array" => [], "is_hash" => Stacker::Pillar(@container={})})})})})
      TPL

      dump = <<-'TPL'
      ---
      foo:
        bar:
        - 1
        - 127.0.0.1
        - true
        is_true: true
        is_false: false
        is_array: []
        is_hash: {}
        nested:
          foo:
            bar:
            - 1
            - 127.0.0.1
            - false
            is_true: true
            is_false: false
            is_array: []
            is_hash: {}

      TPL

      yaml = YAML.parse(File.read("spec/fixtures/test.yml"))
      hash = Stacker::Utils.convert_hash(yaml.as_h)

      hash.inspect.should eq(inspect)
      YAML.dump(hash).should eq(dump)
    end
  end

  describe ".yaml_to_hash" do
    it "convert YAML to internal structure" do
      inspect = <<-'TPL'
      Stacker::Pillar(@container={"foo" => Stacker::Pillar(@container={"bar" => [1, "127.0.0.1", true], "is_true" => true, "is_false" => false, "is_array" => [], "is_hash" => Stacker::Pillar(@container={}), "nested" => Stacker::Pillar(@container={"foo" => Stacker::Pillar(@container={"bar" => [1, "127.0.0.1", false], "is_true" => true, "is_false" => false, "is_array" => [], "is_hash" => Stacker::Pillar(@container={})})})})})
      TPL

      dump = <<-'TPL'
      ---
      foo:
        bar:
        - 1
        - 127.0.0.1
        - true
        is_true: true
        is_false: false
        is_array: []
        is_hash: {}
        nested:
          foo:
            bar:
            - 1
            - 127.0.0.1
            - false
            is_true: true
            is_false: false
            is_array: []
            is_hash: {}

      TPL

      file = "spec/fixtures/test.yml"
      yaml = File.read(file)
      hash = Stacker::Utils.yaml_to_hash(yaml, file)

      hash.inspect.should eq(inspect)
      YAML.dump(hash).should eq(dump)
    end
  end

  describe ".deep_merge" do
    it "deep merges internal structure " do
      dump = <<-'TPL'
      ---
      string: b string
      integer: 2
      is_true: false
      is_false: true
      old_key: foo
      hash:
        foo: bar
        nested:
          hash: bar
          hash1: child1
          array:
          - foo
          - bar
          hash2: child2
        bar: baz
      array:
      - string1
      - 11
      - true
      - false
      - string2
      - 12
      - false
      - true
      new_key: foo

      TPL

      hash1 = load_yaml("spec/fixtures/deep_merge_dict1.yml")
      hash2 = load_yaml("spec/fixtures/deep_merge_dict2.yml")

      Stacker::Utils.deep_merge!(hash1, hash2)
      YAML.dump(hash1).should eq(dump)
    end
  end
end
