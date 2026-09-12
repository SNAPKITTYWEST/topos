# Architecture — Sovereign Logic Escape

## 1. From Physics to Algebra

ENKI's layer simulates stochastic anyon dynamics with continuous poisoning timescales.
The escape maps it to a **deterministic, finite-state, discrete-cost** system so model checkers (ASP/Datalog) and proof assistants can reason about it.

| Physics Concept | Algebraic Encoding |
|---|---|
| Degenerate ground manifold | State `ground_topological` |
| Anyon braiding trajectory | Sequence `gate_pulse ; charge_readout` |
| Quasiparticle poisoning | Event `quasiparticle_tunnel` with cost `0.20` (= entropy drain) |
| Thermal reset / cooldown | Event `reset` with cost `0.05` |
| Decoherence budget | Constraint `Entropy ≤ 0.20` |
| Invalid operation post-collapse | `invalid_op(braiding_transition, quasiparticle_tunnel)` + integrity constraint |

## 2. FSA Semantics

Four states, four events, five transition schemas. The poisoning schema is quantified:

```prolog
transition(S, quasiparticle_tunnel, poisoned_collapse, 0.20) :- state(S), S != poisoned_collapse.
```

This makes the automaton **input-enabled for noise** — any non-collapsed state has a poisoning outgoing edge. The optimization objectives then penalize poisoned states and reward productive ground cycles.

## 3. Timing → Entropy Mapping

The second ASP file derives the latency bound without leaving the entropy model:

* Waiting consumes entropy linearly: `H_wait = λ · T_wait`
* Budget enforces `λ·τ_poison ≤ 0.15`
* Worst case (`τ=1μs`) forces `λ ≤ 150`
* No new physics is introduced — just arithmetic over the given signature.

The rule `valid_reset_sequence/2` is executable: query `?- valid_reset_sequence(T, λ)` to test hardware.

The predicate `unscalable/1` is the **formal specification** of the engineering cliff — any model containing `unscalable(150)` witnesses impossibility; minimizing it drives the solver toward scalable designs.

## 4. Braid Algebra (Topos.Core)

### Design decisions

* **Generators as data, not typeclasses** — keeps rewrite rules pure and serializable for Datalog export.
* **Framing map** carries writhe contribution; `jones` normalizes by `A^{-3w}` explicitly.
* **Rewrite loop** is confluent for the demo density; a full Knuth-Bendix completion would replace the placeholder `ybRewrite`.
* **Polynomials as maps** (`Map Int Integer` for Laurent, `Map (Int,Int) Integer` for HOMFLY) — sparse, canonical, trivially serialized to Datalog facts.
* **Quantum embedding is thin** — `crossingToR` maps `Over→A`, `Under→A⁻¹`; Fibonacci/Ising `quantumDim` and fusion stubs expose the interface without committing to a TQFT backend.

### Equivalence across Kernels

The same Artin relation `σ₁σ₂σ₁ ≡ σ₂σ₁σ₂` appears in **five** places — intentionally redundant for cross-verification:

1. `normalize` / `applyYangBaxter` (Haskell rewrite, `src/Topos/Core.hs:145`)
2. `equiv_word("w_lhs","w_rhs")` (Datalog fact + rules, `datalog/braid_axioms.dl:48`)
3. `Burau` representation (linear sanity check, `src/Topos/Core.hs:580`)
4. `is_yb_window` / `yb_rewrite` / `normalize_yb` (NESL nested-parallel, `nesl/topos.nesl:85`)
5. `YBWindowActor.isYB` / `batch_normalize` (Dataflow array-parallel, `dataflow/topos.df:65`)

All five must agree; `yb_invariance_demo` (NESL) and `assert_yb_invariance` (Dataflow) both witness `j(σ₁σ₂σ₁) == j(σ₂σ₁σ₂)` on sparse Laurent polys — identical to Haskell `jones lhs == jones rhs` and Datalog `equiv("lhs","rhs")`.

This N-way redundancy is intentional: a future Lean/F* backend will unify them as a certified kernel, with NESL/Dataflow as the GPU / streaming execution layer.

## 5. Parallel Models (NESL vs Dataflow)

| Aspect | NESL (`nesl/topos.nesl`) | Dataflow (`dataflow/topos.df`) |
|---|---|---|
| **Model** | Nested sequences `{f(x): x in a}`, `flatten`, divide-and-conquer `reduce`/`scan` | Flat `Arr<T>` + token-driven `Actor` graph, `map_array`/`reduce_array` |
| **YB** | Sliding `windows = {(gs[i],gs[i+1],gs[i+2]): i in [0:n-2]}` + `filter(is_yb_window)` | `YBWindowActor` size-3 `buf`, `isYB` guard, `rewrite` emits 3 tokens |
| **Jones** | `bracket_word` via `reduce(mul_laurent, ...)` over nested factors | `BracketActor` per gen → `AddLaurActor`/`MulLaurActor` merging `Map<exp,coeff>` |
| **Batch** | `{jones(b): b in bs}`, `braid_words` enumerates `|G|^k` | `batch_normalize` / `batch_jones` `map_array` over `BraidRec[]` |
| **Streaming** | `full_normalize = free_reduce→YB→free_reduce` fixpoint | `BraidStreamProcessor` `inject`/`drain` with `FreeReduceActor` chained |

Both are drop-in replacements for the Haskell reference when targeting GPU (NESL `flatten` = GPU flatten) or dataflow hardware (actors = hardware PEs).

## 6. Future Formalization Path

* Replace placeholder `ybRewrite` with a proper permutation of `Over/Under` and add `Reidemeister I` (`Tw` normalization).
* Implement `parseSurface` as a Parsec/Megaparsec recursive descent for the `braid { ... }` syntax; generate both Haskell `Braid` and Datalog `word/2` facts from the same parse.
* Lift ASP `transition/4` into a timed automaton (e.g., UPPAAL) to verify `T_reset < τ_poison` as a property, not just an arithmetic bound.
* Certify `jones` against the bracket polynomial definition in Lean4 — current implementation is a simplified state-sum; the Spec test suite pins writhe/linking invariants as regression guards.
