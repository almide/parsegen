#!/usr/bin/env bash
# The wasm leg is the point of this package, and `almide test` reports a
# lowering wall only as "native fallback". Build a throwaway entry point that
# drives the WHOLE pipeline (grammar → tables → parse → sexpr) for the wasm
# target and fail loudly if anything walls.
set -euo pipefail
cd "$(dirname "$0")/.."
trap 'rm -f src/__wasm_check.almd' EXIT
cat > src/__wasm_check.almd <<'EOF'
import self as parsegen
import self.fixtures_json as fx

effect fn main() -> Unit = {
  let r = parsegen.parse_to_sexpr(fx.grammar_json(), "{\"a\": [1, null, true]}")
  println(match r { ok(s) => s, err(e) => "ERR: " + e })
}
EOF
almide build src/__wasm_check.almd --target wasm -o /tmp/parsegen-wasm-check.wasm
