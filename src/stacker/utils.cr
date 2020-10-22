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
      old_level = Stacker::Processor::Log.level

      begin
        Stacker::Processor::Log.level = new_level
        Stacker::Renderer::Log.level = new_level
        result = yield
      ensure
        Stacker::Processor::Log.level = old_level
        Stacker::Renderer::Log.level = old_level
      end

      result
    end

    def self.crinja_info(env)
      [env.filters, env.tests, env.functions, env.tags, env.operators].each do |library|
        puts "#{library.name}s:"
        names = library.keys
        names.sort.each do |name|
          feature = library[name]
          puts "  #{feature}"
        end
        puts
      end
    end
  end
end
