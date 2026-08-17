# Conformance ladder

Progress is measured in one way only: **how many `test/corpus/` cases produce the same S-expression as `tree-sitter parse`.**

Grammars are ordered so that each rung introduces exactly one new capability. Every figure below was measured from the `grammar.json` and `scanner.c` shipped in the published crates (August 2026).

- **rules** — entries under `rules`
- **ext** — declared external tokens
- **conf** — declared conflicts
- **scanner** — lines of `scanner.c` that must be rewritten in Almide
- **pat** — regex patterns to compile

## Phase A — no external scanner required

Everything here is pure table generation. Real languages of up to 182 rules are reachable without writing a single line of scanner code.

| | grammar | rules | ext | conf | scanner | pat | new capability | conformance |
|---|---|---:|---:|---:|---:|---:|---|---|
| **A0** | json | 14 | 0 | 0 | 0 | 12 | `grammar.json` → LALR → LR runtime | **6/6** (native; wasm walls upstream) |
| A1 | clojure | 46 | 0 | 0 | 0 | 53 | pattern compilation under load | — |
| **A2** | zig | 108 | 0 | **6** | 0 | 44 | **conflict resolution / GLR** | — |
| A3 | go | 116 | 0 | 8 | 0 | 111 | production-scale grammar | — |
| A4 | java | 168 | 0 | 13 | 0 | 68 | — | — |
| A5 | c | 182 | 0 | **17** | 0 | 77 | conflicts at scale | — |

**A0 decides the project.** json has no external scanner, no conflicts and no precedences — 14 rules of pure skeleton. If the table generator and runtime can reproduce `tree-sitter parse` on json, every structural assumption holds. If not, nothing further is worth building.

**A2 is the reason this order was chosen.** zig, go, java and c declare real conflicts and *no* external tokens, which isolates conflict resolution from scanner work. The two hardest subsystems can be built and verified independently.

## Phase B — external scanners

| | grammar | rules | ext | conf | scanner | pat | new capability | conformance |
|---|---|---:|---:|---:|---:|---:|---|---|
| B0 | css | 66 | 3 | 0 | 100 | 29 | external scanner protocol | — |
| B1 | lua | 71 | 6 | 0 | 195 | 29 | long brackets | — |
| **B2** | python | 149 | 12 | 9 | 437 | 33 | **indentation (INDENT/DEDENT)** | — |
| **B3** | javascript | 142 | 8 | **18** | 364 | 44 | **9 precedences, ASI, regex vs division** | — |

**B3 is the hardest rung in Phase B.** javascript pairs the largest conflict count here with the only non-trivial `precedences` block, an external scanner, and genuine lexical ambiguity — `/` opens a regex literal or divides, depending on parse state.

## Phase C — scale

| | grammar | rules | ext | conf | prec | scanner | pat | conformance |
|---|---|---:|---:|---:|---:|---:|---:|---|
| C0 | rust | 182 | 10 | 8 | 0 | 393 | 23 | — |
| C1 | cpp | 303 | 2 | 33 | 2 | 148 | 103 | — |
| **C2** | **typescript** | 229 | 10 | **48** | **44** | 13 | 42 | — |
| **C3** | **tsx** | 229 | 10 | **49** | **44** | 13 | 42 | — |

**typescript is the summit, not javascript.** 48 conflicts and 44 precedence groups against javascript's 18 and 9. Its scanner is only 13 lines because it reuses javascript's, so what is being tested here is purely the table generator under maximum ambiguity. tsx ships as a separate grammar in the same repository and differs by one conflict; both have to pass.

typescript's generated `parser.c` is **8.4 MB**. Table size, not correctness, is the constraint at this end: grammars have to be loaded as external data rather than compiled into the binary, or the WebAssembly target becomes unusable.

## Out of scope

| grammar | ext | scanner | why |
|---|---:|---:|---|
| yaml | **113** | 1,415 | zero patterns — the language lives entirely in the scanner |
| haskell | 49 | **3,471** | scanner larger than most complete grammars |

## Method

For each grammar:

```
tree-sitter parse --quiet <case>     # oracle
parsegen parse <case>                # under test
```

Cases come from the grammar's own `test/corpus/`. A rung is complete at 100%; partial rates are recorded rather than rounded up.
