module Stacker
  struct Pillar
    alias Type = Bool | Float64 | Float32 | Int64 | Int32 | String | Time | Nil | Pillar | Array(Type)

    def initialize
      @container = {} of String => Type
    end

    delegate each, to: @container
    delegate to_json, to: @container
    delegate to_yaml, to: @container

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
  end
end
