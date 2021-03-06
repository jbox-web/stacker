module Stacker::Runtime::Filter
  # ```
  # {% set arrray  = { "foo": { "bar": ["foo", "bar"] } } | traverse("foo:bar") %}     # => ["foo", "bar"]
  # {% set default = { "foo": { "bar": ["foo", "bar"] } } | traverse("foo:foo", {}) %} # => {}
  # ```
  class Traverse
    Crinja.filter({attribute: nil, default: nil}, :traverse) do
      attribute = arguments["attribute"]
      default = arguments["default"]
      result =
        begin
          Crinja::Resolver.resolve_dig(attribute, target)
        rescue e : Crinja::UndefinedError
          Stacker::Renderer::Log.debug { "Attribute '#{attribute}' not found in traversal path" }
          Crinja::Value.new(nil)
        end

      (result.raw.nil? || result.raw.is_a?(Crinja::Undefined)) ? default : result
    end
  end
end
