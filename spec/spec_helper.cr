require "spec"
require "crystal-env/spec"

require "../src/stacker"

def load_yaml(file)
  yaml = YAML.parse(File.read(file))
  Stacker::Value.convert_hash(yaml.as_h)
end

def create_renderer(doc_root = "spec/fixtures", entrypoint = "spec/fixtures")
  context = Stacker::Context.new(doc_root)
  Stacker::Renderer.new(context, entrypoint)
end
