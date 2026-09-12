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

### Equivalence with Datalog

The same Artin relations appear in three places:

1. `normalize` / `applyYangBaxter` (Haskell rewrite)
2. `equiv_word("w_lhs","w_rhs")` (Datalog fact + rules)
3. `Burau` representation (linear sanity check — braid words that are `equiv_word` must map to the same matrix modulo normalization).

This triple redundancy is intentional: a future Lean/F* backend will unify them as a certified kernel.

## 5. Future Formalization Path

* Replace placeholder `ybRewrite` with a proper permutation of `Over/Under` and add `Reidemeister I` (`Tw` normalization).
* Implement `parseSurface` as a Parsec/Megaparsec recursive descent for the `braid { ... }` syntax; generate both Haskell `Braid` and Datalog `word/2` facts from the same parse.
* Lift ASP `transition/4` into a timed automaton (e.g., UPPAAL) to verify `T_reset < τ_poison` as a property, not just an arithmetic bound.
* Certify `jones` against the bracket polynomial definition in Lean4 — current implementation is a simplified state-sum; the Spec test suite pins writhe/linking invariants as regression guards.
