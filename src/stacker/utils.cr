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
