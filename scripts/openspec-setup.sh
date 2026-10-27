#!/usr/bin/env bash
# Register every OpenSpec store referenced by openspec/config.yaml, then run
# openspec doctor. Only referenced stores are registered. For each store the
# checkout is looked up, in order: $OPENSPEC_STORES_DIR/<id>, the ghorg path
# derived from the remote (~/ghorg/<host>/<group>/<name>), ~/openspec/<id>;
# when none exists the remote is cloned into ${OPENSPEC_STORES_DIR:-~/openspec}/<id>.
# A `ref:` on the reference pins the store: clones check it out, and a
# checkout on another commit is reported (never switched, it may be a working tree).
set -euo pipefail

cfg="${1:-openspec/config.yaml}"
[ -f "$cfg" ] || {
  echo "$cfg not found (run from the repository root)" >&2
  exit 1
}
command -v openspec >/dev/null 2>&1 || {
  echo "openspec is not on PATH (pin 'npm:@fission-ai/openspec' in mise.toml)" >&2
  exit 1
}

registered="$(openspec store list --json 2>/dev/null || echo '{}')"

# Emits one "id remote ref" line per reference; "-" stands for a missing field.
awk '
  function flush() { if (id != "") print id, remote, ref; id = ""; remote = "-"; ref = "-" }
  /^references:/ { r = 1; next }
  r && /^[^ #]/ { r = 0 }
  r && /^  - id:/ { flush(); id = $3 }
  r && /^    remote:/ { remote = $2 }
  r && /^    ref:/ { ref = $2 }
  END { flush() }
' "$cfg" \
  | while read -r id remote ref; do
    if [ "$remote" = "-" ]; then
      echo "store $id: no remote in $cfg; add one under references: so it can be cloned" >&2
      continue
    fi
    dir="$(printf '%s' "$registered" | awk -v id="$id" '$1 == "\"id\":" && $2 == "\"" id "\"," { f = 1; next } f && $1 == "\"root\":" { gsub(/[",]/, "", $2); print $2; exit }')"
    if [ -n "$dir" ]; then
      echo "store $id: already registered ($dir)"
    else
      path="${remote#https://}"
      path="${path#ssh://git@}"
      path="${path#git@}"
      path="${path/://}"
      path="${path%.git}"
      for c in "${OPENSPEC_STORES_DIR:+$OPENSPEC_STORES_DIR/$id}" "$HOME/ghorg/$path" "$HOME/openspec/$id"; do
        if [ -n "$c" ] && [ -f "$c/.openspec-store/store.yaml" ]; then
          dir="$c"
          break
        fi
      done
      if [ -z "$dir" ]; then
        dir="${OPENSPEC_STORES_DIR:-$HOME/openspec}/$id"
        if [ "$ref" = "-" ]; then git clone "$remote" "$dir"; else git clone --branch "$ref" "$remote" "$dir"; fi
      fi
      openspec store register "$dir" --id "$id"
      echo "store $id: registered from $dir"
    fi
    if [ "$ref" != "-" ] && [ -d "$dir/.git" ]; then
      want="$(git -C "$dir" rev-parse --verify --quiet "$ref^{commit}" || true)"
      have="$(git -C "$dir" rev-parse HEAD)"
      if [ -z "$want" ]; then
        echo "store $id: $ref not found in $dir; run: git -C $dir fetch --tags && git -C $dir checkout $ref" >&2
      elif [ "$want" != "$have" ]; then
        echo "store $id: checkout is at $(git -C "$dir" describe --tags --always), $cfg pins $ref; run: git -C $dir checkout $ref" >&2
      fi
    fi
  done

openspec doctor
