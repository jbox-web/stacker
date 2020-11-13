module Stacker::Runtime::Function
  # ```
  # {% do dump({"foo": "bar"}) %}
  # ```
  class Dump
    Crinja.function({object: nil}, :dump) do
      object = arguments["object"]
      Stacker::Renderer::Log.info { "\n#{YAML.dump(object)}" }
      Crinja::Value.new("")
    end
  end
end
