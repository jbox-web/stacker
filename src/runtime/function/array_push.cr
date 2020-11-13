module Stacker::Function
  Crinja.function({array: [] of Crinja::Value, item: nil}, :array_push) do
    array = arguments["array"]
    item = arguments["item"]
    array.push(item)
  end
end
