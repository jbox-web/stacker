target "binary" {
  dockerfile = "Dockerfile"
  platforms  = ["linux/amd64", "linux/arm64"]
  output     = ["packages"]
  target     = "binary-file"
}

target "docker-image" {
  dockerfile = "Dockerfile"
  platforms  = ["linux/amd64", "linux/arm64"]
  output     = [{ type = "docker" }]
  target     = "docker-image"
  tags       = ["stacker-dev:latest"]
}
