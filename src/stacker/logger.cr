module Stacker
  module Logger
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
  end
end
