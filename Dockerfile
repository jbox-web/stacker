#########
# BUILD #
#########

# Build from Crystal upstream
FROM crystallang/crystal:0.36.0-alpine AS builder

# Set build environment
WORKDIR /stacker-build
COPY Makefile shard.yml shard.lock /stacker-build/
COPY src/ /stacker-build/src/
RUN mkdir /stacker-build/bin

# Build the binary
RUN make stacker-static


###########
# RUNTIME #
###########

# Build from Alpine upstream
FROM library/alpine

# Grab stacker binary from **builder** step and inject it in the final image
COPY --from=builder /stacker-build/bin/stacker /usr/local/bin/stacker

# Set runtime environment
WORKDIR /opt/stacker
ENTRYPOINT ["stacker"]
