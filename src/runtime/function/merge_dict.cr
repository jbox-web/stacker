module Stacker::Function
  Crinja.function({hash: nil, other: nil}, :merge_dict) do
    hash = arguments["hash"]
    other = arguments["other"]
    Stacker::Utils.deep_merge_crinja!(hash, other)
    hash
  end
end
