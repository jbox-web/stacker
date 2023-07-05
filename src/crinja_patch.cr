# :nodoc:
class Crinja
  # :nodoc:
  module Resolver
    # :nodoc:
    def self.resolve_dig(name : String, object) : Value
      identifier, _, rest = name.partition(':')

      resolved = resolve_attribute(identifier, object)
      if rest != ""
        resolve_dig(rest, resolved)
      else
        resolved
      end
    end
  end

  # :nodoc:
  struct Value
    # :nodoc:
    def concat(other)
      object = @raw

      if object.is_a?(Array)
        Value.new object.concat(other)
      else
        raise TypeError.new(self, "expected Array for #concat(other : Array), not #{object.class}")
      end
    end

    # :nodoc:
    def push(value)
      object = @raw

      if object.is_a?(Array)
        Value.new object.push(value)
      else
        raise TypeError.new(self, "expected Array for #push(item : Value), not #{object.class}")
      end
    end

    # :nodoc:
    def to_yaml(yaml)
      object = @raw

      case object
      when .is_a?(Hash)
        object.to_yaml(yaml)
      when .is_a?(Array)
        object.to_yaml(yaml)
      when .is_a?(String)
        object.to_yaml(yaml)
      when .is_a?(Number)
        object.to_yaml(yaml)
      when .is_a?(Bool)
        object.to_yaml(yaml)
      when .is_a?(Time)
        object.to_yaml(yaml)
      when .nil?
        object.to_yaml(yaml)
      else
        nil
      end
    end
  end

  # :nodoc:
  def self.value(any : Stacker::Value) : Crinja::Value
    value any.raw
  end

  # :nodoc:
  def self.value(any : JSON::Any) : Crinja::Value
    value any.raw
  end
end
