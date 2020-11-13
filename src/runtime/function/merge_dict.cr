module Stacker::Function
  Crinja.function({hash: nil, other: nil}, :merge_dict) do
    hash = arguments["hash"]
    other = arguments["other"]
    Stacker::Function.deep_merge_crinja!(hash, other)
    hash
  end

  def self.deep_merge_crinja!(hash, other_hash)
    hash = hash.raw
    other_hash = other_hash.raw

    return unless hash.is_a?(Hash) && other_hash.is_a?(Hash)

    other_hash.each do |current_key, other_value|
      this_value = hash[current_key.to_s]?

      hash[Crinja::Value.new(current_key.to_s)] =
        if this_value.nil?
          to_crinja_value(other_value)
        elsif this_value.raw.is_a?(Hash) && other_value.raw.is_a?(Hash)
          to_crinja_value deep_merge_crinja!(this_value, other_value)
        elsif this_value.raw.is_a?(Array) && other_value.raw.is_a?(Array)
          to_crinja_value(this_value.concat(other_value))
        else
          to_crinja_value(other_value)
        end
    end

    hash
  end

  def self.to_crinja_value(value)
    return value if value.is_a?(Crinja::Value)

    Crinja::Value.new(value)
  end
end
