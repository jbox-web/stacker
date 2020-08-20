module Stacker
  module Utils
    def self.file_exists?(file_path)
      File.exists?(file_path)
    end

    def self.load_json_file(file)
      JSON.parse(File.read(file))
    end

    def self.string_to_array(string)
      string.split("\n").reject(&.empty?)
    end

    def self.yaml_to_hash(yaml, file)
      yaml = parse_yaml(yaml, file)

      return nil if yaml.nil?
      return nil if yaml.raw.nil?

      convert_hash(yaml.as_h)
    end

    def self.parse_yaml(string, file)
      begin
        YAML.parse(string)
      rescue e : YAML::ParseException
        Log.error { "Error while parsing yaml #{file}" }
        Log.error { e.message }
        Log.error { string }
        nil
      end
    end

    def self.convert_hash(hash : Hash)
      s = Pillar.new

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

    def self.convert_array(array : Array)
      acc = [] of Stacker::Pillar::Type

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

    def self.deep_merge!(hash, other_hash)
      strategy = other_hash.delete("__") || "merge-last"

      return cleanup(other_hash) if strategy == "overwrite"

      other_hash.each do |current_key, other_value|
        if strategy == "remove"
          hash.delete(current_key)
          next
        end

        this_value = hash[current_key]?

        hash[current_key] =
          if this_value.is_a?(Stacker::Pillar) && other_value.is_a?(Stacker::Pillar)
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
      end

      hash
    end

    def self.concat_list!(list, other_list)
      strategy = "merge-last"
      hash = other_list[0]?

      if hash.is_a?(Stacker::Pillar) && (strat = hash["__"]?)
        strategy = strat
        other_list.delete_at(0)
      end

      if strategy == "overwrite"
        other_list
      elsif strategy == "remove"
        list.select { |i| !other_list.includes?(i) }
      elsif strategy == "merge-first"
        other_list.concat(list)
      else
        list.concat(other_list)
      end
    end

    def self.cleanup(object)
      return object unless object.is_a?(Stacker::Pillar) || object.is_a?(Array)

      if object.is_a?(Stacker::Pillar)
        object.delete("__")
        object.each do |k, v|
          object[k] = cleanup(v)
        end
      elsif object.is_a?(Array)
        hash = object[0]?
        if hash.is_a?(Stacker::Pillar) && (strat = hash["__"]?)
          object.delete_at(0)
        end
      end

      object
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

    SEVERITY_MAP = {
      "trace" => ::Log::Severity::Trace,
      "debug" => ::Log::Severity::Debug,
      "info"  => ::Log::Severity::Info,
      "warn"  => ::Log::Severity::Warn,
      "error" => ::Log::Severity::Error,
      "fatal" => ::Log::Severity::Fatal,
    }

    def self.with_log_level(level, &block)
      new_level = SEVERITY_MAP[level]? || SEVERITY_MAP["info"]
      old_level = Stacker::Log.level

      begin
        Stacker::Log.level = new_level
        result = yield
      ensure
        Stacker::Log.level = old_level
      end

      result
    end
  end
end
