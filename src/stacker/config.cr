module Stacker
  # :nodoc:
  class Config
    include YAML::Serializable

    property doc_root : String
    property entrypoint : String
    property log_file : String
    property stacks : Hash(String, Array(String))

    property server_host : String = "127.0.0.1"
    property server_port : Int32 = 3000
    property server_environment : String = "production"
  end
end
