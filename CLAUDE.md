# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Stacker is a Crystal reimplementation of [Salt PillarStack](https://docs.saltstack.com/en/master/ref/pillar/all/salt.pillar.stack.html): a file-based CMDB that renders a tree of Jinja2 (Crinja) templates into a single merged pillar document for a given host. It ships both a CLI (`stacker fetch`) and an HTTP server (`stacker server`), which Salt consumes as an `ext_pillar` via `salt/stacker.py`.

## Toolchain and tasks

Everything goes through [mise](https://mise.jdx.dev) (`mise.toml`); there is no Makefile for development (`Makefile.release` only drives releases).

```sh
mise dev:deps          # shards install
mise dev:build         # dev binary -> bin/stacker
mise dev:spec          # crystal spec
mise dev:ameba         # bin/ameba, wrapped in `timeout 180` (ameba can spin forever)
mise dev:format        # crystal tool format src/   (note: src/ only, not spec/)
mise dev:doc           # rm -rf docs && crystal doc
mise dev:clean         # rm -rf bin/* lib/
mise release:build     # --release binary + .sha256
mise release:static    # static linux amd64/arm64 binaries via docker buildx bake
```

Run a single spec file or example:

```sh
crystal spec spec/stacker/value_spec.cr
crystal spec spec/stacker/value_spec.cr:45
```

On macOS, `mise dev:fix-shards-command` must be run once before `dev:deps` (workaround for crystal-lang/crystal#16746 — the `shards` binary is missing from the mise install path).

Run the app against the bundled sample project:

```sh
bin/stacker server --config example/stacker.yml
bin/stacker fetch server1.example.net --config example/stacker.yml -g example/grains/server1.json
```

## Architecture

The whole pipeline is ~1200 lines across `src/`. Request flow (identical for CLI and HTTP — both are thin adapters):

`CLI::Fetch` / `Server` → `Runner.process` → `Processor#run` → `Renderer#compile` (Crinja) → `Value.deep_merge!`

- **`Config`** (`config.cr`) — YAML-deserialized `stacker.yml`. `doc_root` is the Crinja template root; `entrypoint` is the subdirectory under it where `<minion_id>.yml` is looked up; `stacks` maps a *namespace* to an ordered list of `.cfg` stack files. Namespaces are the unit of configuration: one Stacker instance serves several, selected by `?n=` or `--namespace`.
- **`Runner`** — the single choke point for both front ends. It validates the host name against `VALID_HOST_NAME` (the name resolves a file path *and* is interpolated in the stack templates, so `..` and separators are rejected), resolves the namespace, and builds a `Renderer` and a `Processor` carrying a `::Log` instance built for that request. `Runner.warmup` pre-builds the shared `Context` at server start.
- **`Errors`** (`errors.cr`) — every failure is a `Stacker::Error` carrying its HTTP status and the JSON body historically returned by the server. `salt/stacker.py` matches on those bodies, so they are part of the contract. The CLI prints the same body and exits 1; the web server maps them through Kemal `error` handlers (Kemal would otherwise render an HTML page for a bare status code).
- **`Context`** — owns the `Crinja` environment (`FileSystemLoader` rooted at `doc_root`, `register_defaults`, `lstrip_blocks`) and caches parsed templates by path and mtime. Shared across requests and rebuilt only when `doc_root` changes.
- **`Renderer`** — compiles one template file with a data hash and **raises `RenderError`** on failure. Never make it degrade to an empty string: an empty render is indistinguishable from a legitimately empty pillar, and Salt would apply the truncated stack.
- **`Processor`** — the core loop. For each `.cfg` stack file: render it (it is itself a template), treat each non-empty output line as a glob relative to the `.cfg`'s directory, then for each matched YAML file render it, parse it into a `Value`, and merge it straight into the accumulating `@stack`. The merge is deliberately direct — routing it through an intermediate `Value` would consume a root level `__` strategy before the stack sees it. The partially-built `@stack` is passed back into every subsequent template render (`compilation_data`), which is what lets later pillars read what earlier ones produced. Any failure (render or YAML) aborts the whole build rather than yielding a partial stack.
- **`Value`** (`value.cr`) — the merge engine and the only non-obvious data structure. A struct wrapping `Hash(String, Type)`, deliberately separate from `YAML::Any`/`JSON::Any` so it can carry the recursive merge semantics. `deep_merge!` implements PillarStack's strategies via a magic `__` key: `merge-last` (default), `merge-first`, `overwrite`, `remove` — for hashes the key sits in the hash, for arrays it sits in a leading element. Two traps, both fixed and covered by fixtures: because `Value` is a **struct**, `overwrite` must replace the receiver's content *in place* (`replace!`) or the caller keeps its old content; and a leading hash in an array is only a marker when it actually carries `__`, otherwise it is data. Any change here must keep `spec/fixtures/merge_strategies/` green.
- **`Logger`** — `Logger.for(source, level, backend)` builds a `::Log` **per request**. Verbosity lives on that instance, never on a shared constant: the previous design mutated class-level `Log` constants, so a concurrent `?l=trace` request dumped other requests' pillars into the log. Do not reintroduce global level mutation.
- **Debug targeting** — `--path`/`p=` and `--step`/`s=` narrow trace output to one file and to specific pipeline steps (`compile`, `yaml-load`, `before-merge`, `after-merge`, `final`), gated by `with_targeted_trace`.

Two patch files monkey-patch upstream shards and are required for the pipeline to work; treat them as first-class code, not cruft:

- `crinja_patch.cr` — adds `Resolver.resolve_dig` (colon-separated traversal used by the `traverse` filter), `Value#concat`/`#push`, a `Value#to_yaml`, and `Crinja.value` overloads that let `Stacker::Value` and `JSON::Any` cross into templates.
- `kemal_patch.cr` — replaces Kemal's startup banner and emits the systemd `READY=1` notification.

Process-level concerns live in `src/stacker.cr`: `VERSION`/`GIT_REF` are baked in at compile time via macro shell-outs (this is why the Dockerfile copies `.git/`), `SIGTERM` stops Kemal and closes the log, and `unknown_args` reports arguments Stacker will not act on so the server refuses to start rather than silently ignoring them — Kemal itself receives no arguments, the listening address always comes from the config file. `SIGUSR1` reopens the log file for logrotate: it must drop **both** `@@log_file` and `@@logger`, since the backend memoizes the `File` and would otherwise keep writing to the rotated one. The CLI is only started when `Crystal.env` is not `test`.

## Extending the template runtime

Filters and functions are one class per file under `src/runtime/filter/` and `src/runtime/function/`, glob-required from `src/stacker.cr` and auto-registered by the `Crinja.filter` / `Crinja.function` macros — no registry to update, just drop the file in and rebuild. Verify registration with `stacker info`, which dumps the full Crinja environment (filters, tests, functions, tags, operators). The doc comment on each class is a runnable Jinja snippet and is published to the API docs; keep that format.

## Testing conventions

Specs are fixture-driven rather than assertion-heavy: a template or input YAML under `spec/fixtures/` is rendered/merged and compared to an expected file under the matching `output/` directory (`YAML.dump(result).should eq(File.read(...))`). `spec/dummy/` holds a miniature doc_root used by `processor_spec.cr`. Adding a merge strategy or filter means adding an input/output fixture pair, not just an inline expectation.

`spec_helper.cr` provides `create_renderer(doc_root:, entrypoint:)`, `load_yaml(file)`, `with_doc_root(files) { |root| }` and `build_stack(root, host)` for throwaway trees, `with_config(yaml) { }`, and `call_request(request)` for HTTP specs.

`call_request` runs the request through Kemal's **exception handler chained to the route handler**, not the route handler alone. That matters: Kemal turns a response status having a registered `error` handler into a `CustomException`, so a route exercised through `RouteHandler` alone returns a body no real client ever receives. An HTTP spec that skips the exception handler will pass while production answers an HTML error page.
