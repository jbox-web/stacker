module Stacker
  class Config
    YAML.mapping(
      doc_root: {
        type:    String,
        nilable: false,
      },
      entrypoint: {
        type:    String,
        nilable: false,
      },
      stacks: {
        type:    Hash(String, Array(String)),
        nilable: false,
      },
      server_host: {
        type:    String,
        default: "127.0.0.1",
      },
      server_port: {
        type:    Int32,
        default: 3000,
      },
      server_environment: {
        type:    String,
        default: "production",
      },
    )

    def to_hash
      Hash(String, String | Array(String)).from_yaml(YAML.dump(self))
    end
  end
end
