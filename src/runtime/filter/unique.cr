module Stacker::Runtime::Filter
  # ```
  # {% set foo = ['a', 'a', 'a'] | unique %} # => ['a']
  # ```
  class Unique
    Crinja.filter(:unique) do
      raw = target.raw

      # Returning an empty string here would silently blank the value instead of
      # reporting that the filter was applied to something it cannot handle.
      raise Crinja::TypeError.new(target, "expected Array for unique filter, not #{raw.class}") unless raw.is_a?(Array)

      value = raw.uniq
      Crinja::Value.new(value)
    end
  end
end
