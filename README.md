# almide/parsegen

A **tree-sitter compatible parser generator**, written in pure [Almide](https://github.com/almide/almide).

It reads tree-sitter's `grammar.json`, generates the parse tables itself, and produces the same syntax trees — with no C toolchain, no dynamic library loading, and no per-language build step. It runs wherever Almide runs, including WebAssembly.

> This is a reimplementation, not a binding. It is not affiliated with the tree-sitter project.

## Compatibility

| | |
|---|---|
| **Input** | tree-sitter's `src/grammar.json`, exactly as committed in every grammar repository |
| **Output** | the same S-expression as `tree-sitter parse` |
| **Verified by** | each grammar's own `test/corpus/`, run against the real `tree-sitter` CLI as the oracle |
| **Queries** | `.scm` query files |
| **Not supported** | executing `grammar.js`; loading `parser.c`, `.so`, or `.wasm` — see below |

Conformance is reported per grammar as a pass rate in [LADDER.md](LADDER.md). That number is the project's only measure of progress.

## Why `grammar.json` and not `grammar.js`

A tree-sitter grammar is authored as JavaScript, and grammars routinely `require()` each other — TypeScript's grammar extends JavaScript's. Reading the source would mean shipping a JavaScript interpreter.

It is not necessary. `tree-sitter generate` writes a fully evaluated `grammar.json` alongside the generated parser, and **every grammar repository commits it**. It is plain JSON with seven top-level keys: `rules`, `extras`, `conflicts`, `precedences`, `externals`, `inline`, `supertypes`.

## Explicitly not compatible: the C ABI

Loading an existing `parser.c` / `.so` / `.wasm` would mean carrying a C runtime. In a WebAssembly build that means running WebAssembly inside WebAssembly, which is not a thing.

Dropping the C ABI is precisely what makes the WebAssembly target possible. It is a **permanent non-goal**, not an unimplemented feature.

## External scanners

Tokens declared in `externals` are produced by hand-written code, not by the tables, and `grammar.json` carries only the declaration. Those have to be rewritten in Almide, once per language.

The trade is favourable. JavaScript's scanner is 364 lines and Python's is 437 — against 142 and 149 grammar rules respectively that come for free.

Two grammars are out of scope for this reason: **yaml** declares 113 external tokens and contains no patterns at all (the language essentially lives in its 1,415-line scanner), and **haskell**'s scanner is 3,471 lines.

## Non-goals

| Not supported | Why |
|---|---|
| C ABI, prebuilt parsers | Would kill the WebAssembly target |
| Executing `grammar.js` | Would require a JavaScript interpreter |
| yaml, haskell | Almost entirely external scanner |
| Incremental reparsing | An editor feature. This is a batch tool |
| Error recovery | Deferred. Useful, but not on the critical path |

## Progress

[LADDER.md](LADDER.md) — grammars ordered so that each rung adds exactly one new capability, with the conformance rate for each.

## Status

**A0 passes on BOTH legs: 6/6 of tree-sitter-json's own corpus, byte-identical
S-expressions, native and wasm, with native/wasm output parity.**
The pipeline is grammar.json → BNF normalization (hidden/synthetic rules,
left-recursive repeats) → SLR(1) tables → state-directed lexing over
[almide/dfa](https://github.com/almide/dfa) (per-state valid-token machines —
tree-sitter's "no separate lexer" property) → LR runtime with extras threading →
canonical S-expression.

The whole pipeline is written PURE-RECURSIVE (state threaded by value, flat
parallel lists, no `mut`-param mutation, no `List[List[…]]` record fields, no
lambdas on the hot path) — the style the wasm value subset admits end to end,
and the discipline almide/dfa established. `tools/wasm-check.sh` is the gate:
`almide test` alone reports a lowering wall only as "native fallback".

## Related

- [almide/dfa](https://github.com/almide/dfa) — the lexer half: pattern set to fused DFA, leftmost-longest
- [almide/tree-sitter-almide](https://github.com/almide/tree-sitter-almide) — the opposite direction: a tree-sitter grammar *for* Almide
