module Stacker::Function
  Crinja.function({object: nil}, :dump) do
    object = arguments["object"]
    Stacker::Renderer::Log.info { "\n#{YAML.dump(object)}" }
    Crinja::Value.new("")
  end
end
