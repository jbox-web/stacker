module Stacker::Runtime::Filter
  # ```
  # {% set foo = ['a', 'a', 'a'] | unique %} # => ['a']
  # ```
  class Unique
    Crinja.filter(:unique) do
      raw = target.raw
      return Crinja::Value.new("") unless raw.is_a?(Array)

      value = raw.uniq
      Crinja::Value.new(value)
    end
  end
end
