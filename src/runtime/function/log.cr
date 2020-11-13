module Stacker::Function
  Crinja.function({object: nil}, :log) do
    object = arguments["object"]
    Stacker::Renderer::Log.info { object }
    Crinja::Value.new("")
  end
end
