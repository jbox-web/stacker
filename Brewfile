# frozen_string_literal: true

# Brewfile — the macOS side of a Crystal project's toolchain.
#
#   brew bundle              install everything listed here
#   brew bundle check        report what is missing, install nothing
#
# WHAT BELONGS HERE, AND WHAT DOES NOT
#   Not the compiler: mise owns Crystal and shards, pinned in mise.toml, so a
#   `brew install crystal` would give the machine a second one and let the two
#   disagree. What belongs here is what mise cannot install and the tasks shell
#   out to — plus mise itself, which has to come from somewhere.
#
#   Nor the libraries the mise-installed Crystal embeds (libgc, pcre2, libyaml,
#   libffi): listing them here invites a version skew that is painful to
#   diagnose. It does NOT embed OpenSSL: a program that requires `openssl` or
#   `http/client` links the one pkg-config finds, Homebrew's on macOS, and
#   dynamically by default. A project that needs it lists it below.

# NOT LISTED ON PURPOSE: WHAT CRYSTALLINE LOADS
#   crystalline, the Crystal language server that mise.toml installs for the
#   editor, is not a self-contained binary on macOS: it loads Homebrew's llvm,
#   libyaml, pcre2 and bdw-gc (otool -L). Three of those are libraries the
#   compiler embeds, the very ones the paragraph above keeps out of this file.
#   Whoever wants the language server installs them by hand (`brew install
#   llvm libyaml pcre2 bdw-gc`); whoever does not sets
#   MISE_DISABLE_TOOLS=aqua:elbywan/crystalline, as the CI does, and mise
#   skips it. Nothing else in the project needs it.

# The Apple bash is 3.2, from 2007: no associative arrays, no `declare -n`,
# none of what a script written this decade assumes. Either install a modern
# one or write every script against 3.2 — deliberately, and in a comment.
brew 'bash'

# The task runner and the toolchain it pins. Everything else in the project is
# driven through `mise <task>`, never through the raw command. mise.toml sets a
# min_version (2026.10.2): the tasks that can spin forever are bounded by mise's
# own task `timeout`, which is why no GNU coreutils is needed here.
brew 'mise'

# Line coverage for `mise dev:coverage`: kcov reads the DWARF of the spec binary.
brew 'kcov'

# --- From here down: keep only what this project actually uses -------------

# The darwin release binaries link openssl@4 statically (static_libs of
# .crystalreleaser.yml): `mise release:static` on a Mac needs the formula.
brew 'openssl@4'

# crystalreleaser builds the linux release binaries in a container
# (release:static, docker strategy of .crystalreleaser.yml).
cask 'docker'
