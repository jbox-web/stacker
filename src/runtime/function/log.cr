module Stacker::Runtime::Function
  # ```
  # {% do log("a string") %}
  # ```
  class Log
    Crinja.function({object: nil}, :log) do
      object = arguments["object"]
      Stacker::Renderer::Log.info { object }
      Crinja::Value.new("")
    end
  end
end
