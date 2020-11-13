module Stacker::Filter
  Crinja.filter(:unique) do
    raw = target.raw
    return Crinja::Value.new("") unless raw.is_a?(Array)

    value = raw.uniq
    Crinja::Value.new(value)
  end
end
