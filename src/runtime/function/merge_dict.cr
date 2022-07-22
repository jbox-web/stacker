module Stacker::Runtime::Function
  # ```
  # {% set hash = {"foo": "bar"} %}
  # {% do merge_dict(hash, {"bar": "baz"}) %} #=> {"foo": "bar", "bar": "baz"}
  # ```
  class MergeDict
    Crinja.function({hash: nil, other: nil}, :merge_dict) do
      hash = arguments["hash"]
      other = arguments["other"]
      Stacker::Runtime::Function::MergeDict.deep_merge_crinja!(hash, other)
      hash
    end

    # Recursively merge two Crinja::Value object.
    #
    # It merges **other_hash** in **hash** and returns the modified **hash**.
    def self.deep_merge_crinja!(hash, other_hash)
      hash = hash.raw
      other_hash = other_hash.raw

      return unless hash.is_a?(Hash) && other_hash.is_a?(Hash)

      other_hash.each do |current_key, other_value|
        new_key = current_key.to_s
        this_value = hash[new_key]?

        new_value =
          if this_value.nil?
            other_value
          elsif this_value.raw.is_a?(Hash) && other_value.raw.is_a?(Hash)
            deep_merge_crinja!(this_value, other_value)
          elsif this_value.raw.is_a?(Array) && other_value.raw.is_a?(Array)
            this_value.concat(other_value)
          else
            other_value
          end

        hash[Crinja::Value.new(new_key)] = to_crinja_value(new_value)
      end

      hash
    end

    # Convert any value in Crinja::Value.
    def self.to_crinja_value(value)
      return value if value.is_a?(Crinja::Value)

      Crinja::Value.new(value)
    end
  end
end
