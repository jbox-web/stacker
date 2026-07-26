module Stacker::Runtime::Filter
  # Dump an object to JSON, without character escaping.
  #
  # ```
  # {% set json = {"foo": "bar"} | json %}
  # ```
  #
  # The output is pretty printed, indented with 2 spaces unless another **indent**
  # width is given: `{"foo": "bar"} | json` renders as `{`, `  "foo": "bar"`, `}`
  # on three lines.
  class Json
    Crinja.filter({indent: nil}, :json) do
      raw = target.raw
      indent = arguments.fetch("indent", 2).to_i
      String.build do |io|
        Crinja::JsonBuilder.to_json(io, raw, indent)
      end
    end
  end
end
