module Stacker
  # `Value` represents an object inside the Stacker runtime.
  #
  # It wraps a Crystal value in #raw and defines methods to access properties of the wrapped value while being agnostic about the actual type of the wrapped raw value.
  struct Value
    # Raw type wrapped by `Value`.
    alias Type = Bool | Float64 | Float32 | Int64 | Int32 | String | Time | Nil | Value | Array(Type)

    def initialize
      @container = {} of String => Type
    end

    delegate each, to: @container
    delegate delete, to: @container
    delegate to_json, to: @container
    delegate to_yaml, to: @container

    # Parse **yaml** and convert the result object into Stacker::Value object.
    def self.from_yaml(yaml : String)
      yaml = YAML.parse(yaml)

      return nil if yaml.nil?
      return nil if yaml.raw.nil?

      convert_hash(yaml.as_h)
    end

    # Convert a Hash object into a Stacker::Value object.
    def self.convert_hash(hash : Hash)
      s = new

      hash.each do |k, v|
        k = k.raw if k.responds_to?(:raw)
        v = v.raw if v.responds_to?(:raw)

        next if v.is_a?(Set) || v.is_a?(Slice)

        if v.is_a?(Hash)
          v = convert_hash(v)
        elsif v.is_a?(Array)
          v = convert_array(v)
        end

        s[k.to_s] = v
      end

      s
    end

    # Convert an Array object into a Stacker::Value object.
    def self.convert_array(array : Array)
      acc = [] of Type

      array.each do |val|
        val = val.raw if val.responds_to?(:raw)

        next if val.is_a?(Set) || val.is_a?(Slice)

        acc <<
          if val.is_a?(Hash)
            convert_hash(val)
          elsif val.is_a?(Array)
            convert_array(val)
          else
            val
          end
      end

      acc
    end

    # Recursively merge two Stacker::Value object.
    #
    # It merges **other_hash** in **hash** and returns the modified **hash**.
    def self.deep_merge!(hash, other_hash)
      strategy = other_hash.delete("__") || "merge-last"

      return cleanup_hash!(other_hash) if strategy == "overwrite"

      other_hash.each do |current_key, other_value|
        if strategy == "remove"
          hash.delete(current_key)
          next
        end

        this_value = hash[current_key]?

        new_value =
          if this_value.is_a?(Stacker::Value) && other_value.is_a?(Stacker::Value)
            if strategy == "merge-first"
              deep_merge!(other_value, this_value)
            else
              deep_merge!(this_value, other_value)
            end
          elsif this_value.is_a?(Array) && other_value.is_a?(Array)
            concat_list!(this_value, other_value)
          else
            other_value
          end

        hash[current_key] = new_value
      end

      hash
    end

    private def self.cleanup_hash!(object)
      return object unless object.is_a?(Stacker::Value) || object.is_a?(Array)

      if object.is_a?(Stacker::Value)
        object.delete("__")
        object.each do |k, v|
          object[k] = cleanup_hash!(v)
        end
      elsif object.is_a?(Array)
        hash = object[0]?
        if hash.is_a?(Stacker::Value)
          object.delete_at(0)
        end
      end

      object
    end

    private def self.concat_list!(list, other_list)
      strategy = "merge-last"
      hash = other_list[0]?

      if hash.is_a?(Stacker::Value) && (strat = hash["__"]?)
        strategy = strat
        other_list.delete_at(0)
      end

      retval =
        case strategy
        when "overwrite"
          other_list
        when "remove"
          list.select { |i| !other_list.includes?(i) }
        when "merge-first"
          other_list.concat(list)
        else
          # merge-last (default)
          list.concat(other_list)
        end

      retval
    end

    def [](key : String)
      @container[key]
    end

    def []?(key : String)
      @container[key]?
    end

    def []=(key : String, value)
      @container[key] = value
    end

    def raw
      @container
    end

    def deep_merge!(other)
      self.class.deep_merge!(self, other)
    end
  end
end
