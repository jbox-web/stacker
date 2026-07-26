module Stacker::Runtime::Function
  # ```
  # {% set array = [] %}
  # {% do array_push(array, "foo") %} # => ['foo']
  # ```
  class ArrayPush
    Crinja.function({array: [] of Crinja::Value, item: nil}, :array_push) do
      array = arguments["array"]
      item = arguments["item"]
      array.push(item)
    end
  end
end
