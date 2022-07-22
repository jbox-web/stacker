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
  end
end
