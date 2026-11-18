#!/usr/bin/env bash
# Assembles the licenses/ folder baked into the binary from licenses.manifest:
# shard texts are copied from disk; clib/runtime texts are grouped by SPDX id
# from the committed canonical texts in licenses-spdx/.
#
# WHY THIS EXISTS
#   A statically linked binary carries its dependencies' code, so it has to
#   carry their notices too. Harvesting them at build time — rather than
#   committing a hand-written NOTICE that rots — keeps the shipped artifact
#   honest as the dependency list moves.
#
# WHERE IT GOES
#   scripts/harvest-licenses.sh, driven by the `dev:licenses` mise task, which
#   every task that compiles the application declares in its `depends`. The
#   folder is generated, so it belongs in .gitignore — and a CI job that runs a
#   compiling task standalone will otherwise fail at macro time, since the
#   folder is read while the compiler runs.
#
# THE TWO INPUTS THE PROJECT OWNS
#   licenses.manifest — one entry per line, `kind | name | source`:
#       shard   | mcp      | lib/mcp/LICENSE      on-disk text, copied verbatim
#       project | myapp    | LICENSE              same, for the project itself
#       clib    | openssl  | Apache-2.0           SPDX id, grouped by that id
#       runtime | libgc    | Boehm-GC             same
#       clib    | libyaml  | licenses-upstream/libyaml.txt
#                                                 on-disk text, copied verbatim
#     `#` starts a comment, at the start of a line or after an entry. A name
#     may not start with `clib-`: that prefix is the one of the grouped files
#     written below. shard/project entries carry a real copyright line,
#     so they are copied as-is; clib/runtime entries share one canonical text
#     between several dependencies, hence the grouping.
#
#     A clib/runtime source that is a file is copied verbatim instead. That is
#     the form to use whenever the license asks for the copyright notice to be
#     reproduced (MIT, BSD, zlib): the SPDX text of those is a template whose
#     copyright line is a blank (`<year> <copyright holders>`), and shipping
#     the blank is shipping no notice. Commit the library's own license file,
#     taken from its sources at the version actually linked.
#   licenses-spdx/<id>.txt — the canonical text of each SPDX id used above,
#     committed once and never edited.
#
# The missing-file cases are hard errors on purpose: a notice silently absent
# from a redistributed binary is the failure this script exists to prevent.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
MANIFEST=licenses.manifest
OUT=licenses

# A project that bakes no licenses can delete this script, the task and its
# `depends`. Until it does, skipping cleanly beats failing every build.
if [ ! -f "$MANIFEST" ]; then
  echo "harvest: no $MANIFEST, nothing to assemble"
  exit 0
fi

# Assembled beside the output, then swapped in by two renames: every compiling
# task depends on this script and reads licenses/ at macro time, so a second
# task started meanwhile must never see the directory half filled. (It can miss
# it for the instant between the two renames: a directory cannot be replaced by
# another in one step.)
BUILD="$OUT.tmp.$$"
OLD="$OUT.old.$$"
# Whatever ends the script, nothing of it is left behind: the work directory
# goes, and a licenses/ that was moved aside and not replaced yet comes back.
# INT and TERM are turned into an exit so that this runs for them too: bash
# skips the EXIT trap when a signal it does not trap kills it.
cleanup() {
  rm -rf "$BUILD"
  if [ -d "$OLD" ]; then
    if [ -d "$OUT" ]; then rm -rf "$OLD"; else mv "$OLD" "$OUT"; fi
  fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
rm -rf "$BUILD"
mkdir -p "$BUILD"

# clib/runtime licenses are grouped by SPDX id. macOS ships bash 3.2 (no
# associative arrays), so accumulate the "used by" names in per-id list files
# under a hidden scratch dir instead of `declare -A`. The dir is removed before
# the final count so it never lands in the baked output.
SCRATCH="$BUILD/.used"
mkdir -p "$SCRATCH"

# printf, not echo, wherever a field is written: an entry named `-n` or `-e`
# is an option to echo, which then prints nothing.
entries=0
while IFS='|' read -r kind name source; do
  # A comment after the entry.
  source="${source%%#*}"
  kind="$(printf '%s' "$kind" | tr -d '[:space:]')"
  name="$(printf '%s' "$name" | tr -d '[:space:]')"
  source="$(printf '%s' "$source" | tr -d '[:space:]')"
  [ -z "$kind" ] && continue
  case "$kind" in
    \#*) continue ;;
  esac
  # An empty name would write a hidden ".txt" nothing embeds; a repeated one
  # would overwrite the notice written for the first. Either way a notice
  # would go missing without a word.
  if [ -z "$name" ]; then
    echo "harvest: an entry of kind '$kind' has no name" >&2
    exit 1
  fi
  # A fixed string after `--`: as a pattern, `a.c` matched an earlier `abc`,
  # and a name starting with a dash was read as an option of grep, which then
  # waited on the manifest itself as its input.
  if [ -e "$BUILD/$name.txt" ] || grep -qxF -- "$name" "$SCRATCH/names" 2>/dev/null </dev/null; then
    echo "harvest: two entries are named '$name'" >&2
    exit 1
  fi
  # clib-<id>.txt is where the grouped notices go: an entry of that name would
  # be overwritten by its group, without a word.
  case "$name" in
    clib-*)
      echo "harvest: the name '$name' starts with clib-, the prefix of the grouped notices" >&2
      exit 1
      ;;
  esac
  printf '%s\n' "$name" >> "$SCRATCH/names"
  entries=$((entries + 1))
  case "$kind" in
    shard|project)
      # On-disk license text copied verbatim (carries a real copyright line):
      # shards from lib/<name>/LICENSE, the project from the root LICENSE.
      if [ ! -f "$source" ]; then
        echo "harvest: missing license '$source' for '$name' (run shards install / the submodule plan)" >&2
        exit 1
      fi
      cp "$source" "$BUILD/$name.txt"
      ;;
    clib|runtime)
      if [ -f "$source" ]; then
        # The library's own license file: verbatim, under the library's name.
        cp "$source" "$BUILD/$name.txt"
      elif [ -f "licenses-spdx/$source.txt" ]; then
        printf '%s\n' "$name" >> "$SCRATCH/$source.list"
      else
        echo "harvest: '$source' for '$name' is neither a file nor an SPDX id of licenses-spdx/" >&2
        exit 1
      fi
      ;;
    *)
      # A misspelt kind would otherwise drop the notice without a word.
      echo "harvest: unknown kind '$kind' for '$name' (expected shard, project, clib or runtime)" >&2
      exit 1
      ;;
  esac
done < <(grep -v '^#' "$MANIFEST")

# A manifest that lists nothing is a mistake, not a project without notices:
# that one has no manifest at all (see above).
if [ "$entries" -eq 0 ]; then
  echo "harvest: $MANIFEST holds no entry" >&2
  exit 1
fi

# Sorted glob → deterministic baked output. Join the accumulated names with ", ".
for list in "$SCRATCH"/*.list; do
  [ -e "$list" ] || continue
  id="$(basename "$list" .list)"
  names="$(awk 'NR>1{printf ", "} {printf "%s", $0} END{print ""}' "$list")"
  {
    echo "Used by: $names"
    echo
    cat "licenses-spdx/$id.txt"
  } > "$BUILD/clib-$id.txt"
done

rm -rf "$SCRATCH"

# What was assembled, to compare with what ends up in place.
assembled="$(cd "$BUILD" && cksum -- * | LC_ALL=C sort)"

# `mv` onto a directory that exists moves INTO it. When another run swapped its
# own output in between the two renames below, ours lands inside it: that
# output is complete and comes from the same manifest, so ours is dropped.
rm -rf "$OLD"
if [ -d "$OUT" ]; then mv "$OUT" "$OLD" 2>/dev/null || true; fi
mv "$BUILD" "$OUT"
rm -rf "$OLD" "$OUT/$(basename "$BUILD")"

# The first rename is allowed to fail (the race above), so its failure is not
# an error by itself; what is one is a licenses/ that does not hold what was
# just assembled, whatever the reason: stale notices must not pass for fresh.
if [ "$(cd "$OUT" && cksum -- * | LC_ALL=C sort)" != "$assembled" ]; then
  echo "harvest: $OUT/ does not hold what was just assembled" >&2
  exit 1
fi

echo "harvested $(find "$OUT" -maxdepth 1 -type f | wc -l | tr -d ' ') license files into $OUT/"
