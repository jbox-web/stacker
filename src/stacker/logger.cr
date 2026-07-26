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

    # Translate a log level name into a `::Log::Severity`, defaulting to `Info`.
    def self.severity(level : String) : ::Log::Severity
      SEVERITY_MAP[level.downcase]? || SEVERITY_MAP["info"]
    end

    # Build a `::Log` instance dedicated to a single stack build.
    #
    # The severity lives on the instance, never on a shared constant: two builds
    # running concurrently cannot change each other's verbosity, which used to leak
    # one request's pillars into the log at the verbosity asked by another one.
    def self.for(source : String, level : String, backend : ::Log::Backend? = nil) : ::Log
      ::Log.new(source, backend || Stacker.logger, severity(level))
    end
  end
end
