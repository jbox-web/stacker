require "../spec_helper.cr"

private def config_for(root)
  <<-YAML
  ---
  doc_root: #{root}
  entrypoint: sp
  log_file: stdout
  stacks:
    default:
      - #{root}/sp/stack.cfg
  YAML
end

private FILES = {
  "sp/stack.cfg"  => "base.yml\n{{ minion_id }}.yml\n",
  "sp/base.yml"   => "base:\n  a: 1\n",
  "sp/h1.yml"     => "host:\n  b: 2\n",
  "sp/broken.yml" => "host: {{ nope | nosuchfilter }}\n",
  "private/s.yml" => "secret:\n  api_key: SUPERSECRET\n",
}

private def json_post(path, body)
  headers = HTTP::Headers{"Content-Type" => "application/json"}
  call_request(HTTP::Request.new("POST", path, headers, body))
end

describe Stacker::Server do
  describe "GET /:host" do
    it "should return the stack as JSON" do
      with_doc_root(FILES) do |root|
        with_config(config_for(root)) do
          response = call_request(HTTP::Request.new("GET", "/h1"))
          response.status_code.should eq(200)
          response.body.should eq(%({"base":{"a":1},"host":{"b":2}}))
        end
      end
    end

    it "should answer 404 for an unknown host" do
      with_doc_root(FILES) do |root|
        with_config(config_for(root)) do
          response = call_request(HTTP::Request.new("GET", "/nope"))
          response.status_code.should eq(404)
          response.body.should eq(%({"404":"Stacker: host not found"}))
        end
      end
    end

    it "should answer 404 for an unknown namespace" do
      with_doc_root(FILES) do |root|
        with_config(config_for(root)) do
          response = call_request(HTTP::Request.new("GET", "/h1?n=nope"))
          response.status_code.should eq(404)
          response.body.should eq(%({"404":"Stacker: namespace not found"}))
        end
      end
    end

    it "should answer 500 without leaking internals when a template is broken" do
      with_doc_root(FILES) do |root|
        with_config(config_for(root)) do
          response = call_request(HTTP::Request.new("GET", "/broken"))
          response.status_code.should eq(500)
          response.body.should_not contain("nosuchfilter")
          response.body.should contain("500")
        end
      end
    end
  end

  describe "unmatched route" do
    # Kemal answers unknown routes with an HTML page by default, which the Salt
    # module would try to parse as JSON.
    it "should answer 404 as JSON" do
      with_doc_root(FILES) do |root|
        with_config(config_for(root)) do
          response = call_request(HTTP::Request.new("GET", "/a/b"))
          response.status_code.should eq(404)
          response.body.should eq(%({"404":"Stacker: error"}))
        end
      end
    end
  end

  describe "POST /:host" do
    it "should build the stack from the posted grains" do
      with_doc_root(FILES) do |root|
        with_config(config_for(root)) do
          response = json_post("/h1", %({"grains": {"id": "h1"}, "pillar": {}}))
          response.status_code.should eq(200)
          response.body.should eq(%({"base":{"a":1},"host":{"b":2}}))
        end
      end
    end

    # POST is the method the Salt module uses, and it is not normalized by the router:
    # an encoded `../` used to read any .yml file on the filesystem.
    it "should reject a traversal attempt" do
      with_doc_root(FILES) do |root|
        with_config(config_for(root)) do
          response = json_post("/..%2fprivate%2fs", "{}")
          response.status_code.should eq(400)
          response.body.should eq(%({"400":"Stacker: invalid host name"}))
          response.body.should_not contain("SUPERSECRET")
        end
      end
    end

    it "should answer 400 on a malformed body" do
      with_doc_root(FILES) do |root|
        with_config(config_for(root)) do
          response = json_post("/h1", "not json")
          response.status_code.should eq(400)
          response.body.should eq(%({"400":"Stacker: invalid request body"}))
        end
      end
    end

    it "should answer 400 when grains is not an object" do
      with_doc_root(FILES) do |root|
        with_config(config_for(root)) do
          response = json_post("/h1", %({"grains": ["a"]}))
          response.status_code.should eq(400)
          response.body.should eq(%({"400":"Stacker: invalid request body"}))
        end
      end
    end
  end
end
