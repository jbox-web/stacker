require "spec"
require "crystal-env/spec"

require "../src/stacker"

def load_yaml(file)
  yaml = YAML.parse(File.read(file))
  Stacker::Pillar.convert_hash(yaml.as_h)
end

def create_renderer
  context = Stacker::Context.new("spec/fixtures")
  Stacker::Renderer.new(context, "spec/fixtures")
end
