require "spec"

require "../src/stacker"

def load_yaml(file)
  yaml = YAML.parse(File.read(file))
  Stacker::Utils.convert_hash(yaml.as_h)
end

def create_renderer
  Stacker::Renderer.new("spec/fixtures", "spec/fixtures")
end
