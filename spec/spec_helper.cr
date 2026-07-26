require "spec"
require "file_utils"
require "crystal-env/spec"

require "../src/stacker"

# Keep the loggers out of the spec output: specs that assert on log output bind
# their own memory backend.
Spec.before_suite do
  Log.setup(:none)
  Stacker.logger = Log::MemoryBackend.new

  # `Log.for(source, level)` pins the level, so `Log.setup` alone does not silence
  # these: their backend has to be swapped explicitly.
  [Stacker::Runner::Log, Stacker::Processor::Log, Stacker::Renderer::Log, Stacker::Server::Log].each do |log|
    log.backend = Log::MemoryBackend.new
  end
end

def load_yaml(file)
  yaml = YAML.parse(File.read(file))
  Stacker::Value.convert_hash(yaml.as_h)
end

def create_renderer(doc_root = "spec/fixtures", entrypoint = "spec/fixtures", log = Stacker::Logger.for("renderer", "info", Log::MemoryBackend.new))
  context = Stacker::Context.new(doc_root)
  Stacker::Renderer.new(context, entrypoint, log)
end

# Build a throwaway doc_root on disk and yield its path.
#
# **files** maps a path relative to the doc_root to its content.
def with_doc_root(files : Hash(String, String), &)
  root = File.tempname("stacker-spec")

  files.each do |path, content|
    full_path = File.join(root, path)
    Dir.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)
  end

  begin
    yield root
  ensure
    FileUtils.rm_rf(root)
  end
end

# Run the whole stack build for **host_name** against a throwaway doc_root.
def build_stack(root, host_name, entrypoint = "sp", stacks = ["stack.cfg"], level = "info", backend = Log::MemoryBackend.new)
  context = Stacker::Context.new(root)
  renderer = Stacker::Renderer.new(context, entrypoint, Stacker::Logger.for("renderer", level, backend))
  processor = Stacker::Processor.new(renderer, stacks.map { |stack| File.join(root, entrypoint, stack) }, Stacker::Logger.for("processor", level, backend))
  processor.run(host_name, {} of String => String, {} of String => String, "default", "", Stacker::Processor.valid_steps)
end

# Load a config from an inline YAML string, for the duration of the block.
def with_config(yaml : String, &)
  previous = Stacker.config?
  Stacker.config = Stacker::Config.from_yaml(yaml)
  begin
    yield
  ensure
    Stacker.config = previous
  end
end

# Issue a request against the Kemal routes without starting a server.
#
# The exception handler is part of the chain on purpose: Kemal turns a response
# status that has a registered error handler into a `CustomException`, so a route
# tested through `RouteHandler` alone does not produce the response a client gets.
def call_request(request : HTTP::Request) : HTTP::Client::Response
  io = IO::Memory.new
  response = HTTP::Server::Response.new(io)
  context = HTTP::Server::Context.new(request, response)

  Kemal::ExceptionHandler::INSTANCE.next = Kemal::RouteHandler::INSTANCE
  Kemal::ExceptionHandler::INSTANCE.call(context)

  response.close
  io.rewind
  HTTP::Client::Response.from_io(io, decompress: false)
end
