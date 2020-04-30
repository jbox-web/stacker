module Crinja::Resolver
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

struct Crinja::Value
  def concat(other)
    object = @raw

    if object.is_a?(Array)
      Value.new object.concat(other)
    else
      raise TypeError.new(self, "expected Array for #concat(other : Array), not #{object.class}")
    end
  end

  def push(value)
    object = @raw

    if object.is_a?(Array)
      Value.new object.push(value)
    else
      raise TypeError.new(self, "expected Array for #push(item : Value), not #{object.class}")
    end
  end

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
    when .is_a?(Nil)
      object.to_yaml(yaml)
    else
      nil
    end
  end
end
