###########
# CRYSTAL #
###########

FROM alpine:3.24 AS crystal

RUN apk add --update --no-cache \
  crystal=~1.20 \
  shards \
  bash \
  gc-dev \
  gc-static \
  git \
  libxml2-dev \
  libxml2-static \
  openssl-dev \
  openssl-libs-static \
  gmp-dev \
  gmp-static \
  pcre2-dev \
  pcre2-static \
  xz-dev \
  xz-static \
  yaml-dev \
  yaml-static \
  zlib-dev \
  zlib-static

#########
# BUILD #
#########

# The static binary of the docker image only. The released binaries are built
# by crystalreleaser (.crystalreleaser.yml), in an image of its own.
FROM crystal AS build-binary-file

WORKDIR /build
# The whole history is needed here: `Stacker::VERSION` and `Stacker::GIT_REF` are
# stamped at compile time by `shards version` and `git log`. LICENSE,
# licenses.manifest and the licenses-* folders feed the harvest of the
# third-party notices the binary embeds.
COPY .git/ /build/.git/
COPY shard.yml shard.lock LICENSE licenses.manifest /build/
COPY licenses-spdx/ /build/licenses-spdx/
COPY licenses-upstream/ /build/licenses-upstream/
COPY scripts/harvest-licenses.sh /build/scripts/
COPY src/ /build/src/
RUN mkdir -p bin \
 && shards install --production \
 && bash scripts/harvest-licenses.sh \
 && crystal build --threads 4 --release --error-trace --static -o bin/stacker src/stacker.cr

###########
# RUNTIME #
###########

# Build distroless images \o/
FROM gcr.io/distroless/static-debian12 AS docker-image

# Grab stacker binary from **build-binary-file** step and inject it in the final image
COPY --from=build-binary-file /build/bin/stacker /usr/bin/stacker

# Set runtime environment
USER nonroot
ENV USER=nonroot
ENV HOME=/home/nonroot
WORKDIR /home/nonroot
ENTRYPOINT ["stacker"]
