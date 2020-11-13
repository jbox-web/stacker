module Stacker::Runtime::Filter
  # ```
  # {% set json = {"foo": "bar"} | json %} # => {"foo": "bar"}
  # ```
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
