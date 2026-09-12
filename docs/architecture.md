<!-- COMMENT SOVEREIGN LEVIATHAN COVENANT - FRAGMENT BINDING; -->
<!-- COMMENT Node-ID: TOPOS-FILE-016-Architecture; -->
<!-- COMMENT Parent-Work: topos; -->
<!-- COMMENT Parent-Covenant: SL-AGPL3-001; -->
<!-- COMMENT Copyright: 2026 SNAPKITTYWEST; -->
<!-- COMMENT License-ID: SL-AGPL3-001 / MGPLv3; -->
<!-- COMMENT Covenant-Version: 1.0; -->
<!-- COMMENT Source-Hash: sha256:18f94c97566beb85fa660f7751afc4ab47542c703827538a3e3ed1247f70cd60; -->
<!-- COMMENT Hash-Scope: source before generated license headers, UTF-8 LF; -->
<!-- COMMENT Creation-Date: 2026-09-12 (provenance record); -->
<!-- COMMENT Modification-Record: added license and node headers only; -->
<!-- COMMENT Verification-Record: text preservation checked, compilation not verified; -->
<!-- COMMENT Governed by GNU Affero General Public License version 3; -->
<!-- COMMENT together with applicable Sovereign Leviathan additional terms; -->
<!-- COMMENT AGPLv3 terms remain authoritative where additional terms do not validly apply; -->
<!-- COMMENT See LICENSE and docs/PROVENANCE.md; -->
<!-- COMMENT  -->
<!-- COMMENT ===========================================================; -->
<!-- COMMENT SOVEREIGN NODE KEY: TOPOS-FILE-016-Architecture-BLK-001-001-1; -->
<!-- COMMENT Parent-ID: TOPOS-FILE-016-Architecture; -->
<!-- COMMENT License-ID: SL-AGPL3-001 / MGPLv3; -->
<!-- COMMENT Covenant-Version: 1.0; -->
<!-- COMMENT Copyright: 2026 SNAPKITTYWEST; -->
<!-- COMMENT License-Location: LICENSE; -->
<!-- COMMENT Provenance: docs/NODE_MANIFEST.json; -->
<!-- COMMENT BLOCK 001; -->
<!-- COMMENT Component: architecture.md; -->
<!-- COMMENT Purpose: architecture 10-way YB equivalence; -->
<!-- COMMENT Inputs: varies; -->
<!-- COMMENT Outputs: varies; -->
<!-- COMMENT ===========================================================; -->
<!-- COMMENT  -->
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

The same Artin relation `σ₁σ₂σ₁ ≡ σ₂σ₁σ₂` appears in **ten** places — intentionally redundant for cross-verification:

1. `normalize` / `applyYangBaxter` (Haskell rewrite, `src/Topos/Core.hs:145`)
2. `equiv_word("w_lhs","w_rhs")` (Datalog fact + rules, `datalog/braid_axioms.dl:48`)
3. `Burau` representation (linear sanity check, `src/Topos/Core.hs:580`)
4. `is_yb_window` / `yb_rewrite` / `normalize_yb` (NESL nested-parallel, `nesl/topos.nesl:85`)
5. `YBWindowActor.isYB` / `batch_normalize` (Dataflow array-parallel, `dataflow/topos.df:65`)
6. `kauffmanBracket lhsYB == rhsYB` / `jonesYB` (Liquid `KauffmanKhovanov.hs:183`)
7. `dSquaredZero` + `differential` sign-cancellation (Liquid `KhovanovDifferential.hs:254`) — YB is the `d²=0` coherence
8. `dSquared` / `dCob` via `evalCob` (TQFT Cobordism `TQFT/Cobordism.hs:222`, geometry → Merge/Split cobordism)
9. `sphere*` / `neckCutting` / `delooping` (Bar-Natan `BarNatan/DottedCobordism.hs:103`, BN1-BN6)
10. `F_comp` / `dTQFT` / `homologyFunctor` (Functor `TQFT/Functor.hs:86`, `F:Cob→Vect` preserves `Compose` → `d²=0` on homology)

All ten must agree; `yb_invariance_demo` (NESL), `assert_yb_invariance` (Dataflow), `bracketYB`/`jonesYB` (Liquid), `dSquared`/`dSquaredZero` (all three TQFT layers) all witness `j(σ₁σ₂σ₁) == j(σ₂σ₁σ₂)` — identical to `jones lhs == jones rhs` and `equiv("lhs","rhs")`.

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

## 6. Liquid Verification (Kauffman → Khovanov)

* `KauffmanKhovanov.hs` reflection/PLE proves **bracket invariance under RII/RIII** (`bracketYB`), hence Jones via `A^{-3·writhe}` is a link invariant. The state-sum `kauffmanBracket = Σ_s A^{#A}·A^{-#A⁻¹}·δ^{circles-1}` `KauffmanKhovanov.hs:119` is the executable spec that `Topos.Core:jones` approximates with `Map`-based polys.
* `eulerJones` `KauffmanKhovanov.hs:288` proves **Khovanov Euler characteristic = Jones** — the categorification is sound. `khovanovComplex` builds `2^{#crossings+k}` enhanced states with `(i,q)` gradings.
* `KhovanovDifferential.hs` implements the **Frobenius TQFT** `m/delta` `KhovanovDifferential.hs:92` and signed `d` `KhovanovDifferential.hs:210`. `dSquaredZero` `KhovanovDifferential.hs:254` (`d(d ch)==[]`) is exactly the Yang-Baxter coherence (two orders of flipping two `0→1` bits cancel via `signOf`).
* Together they certify that the NESL/Dataflow rewrites are not just string rewrites but **chain-homotopy equivalences** of Khovanov complexes.

## 7. TQFT Cobordism Double-Layer (`TQFT/Cobordism.hs`)

* **Layer 1** Frobenius `A=Z[X]/X²` `TQFT/Cobordism.hs:33` — same `mult`/`comult` as Khovanov but with algebra lemmas `multUnitLeft/Right`, `multAssociative`, `comultCounit` discharged by SMT. This is the *algebraic TQFT*.
* **Layer 2-3** `Cobordism` ADT `TQFT/Cobordism.hs:82` + `evalCob` `TQFT/Cobordism.hs:113` — the *geometric TQFT functor* on dotted cobordisms (birth/death/merge/split/dot). `Compose` nested evaluation `evalCob f (evalCob g lab)` is functoriality.
* **Layer 4-5** `KhGen`/`dCob` `TQFT/Cobordism.hs:156` reuses `geometryToCob` + `signOf`; `dSquared` `TQFT/Cobordism.hs:222` re-proves `d²=0` now *via cobordism evaluation* — the YB relation becomes a neck-cutting identity.
* **Layer 6** `categorification` `TQFT/Cobordism.hs:242` : `{jonesFromEuler (khComplex b)==jonesPoly b}` — second proof of Euler=Jones, now through cobordisms.
* **Layer 9** `neckCutting/delooping/frobenius` `TQFT/Cobordism.hs:292` — Bar-Natan relations as SMT obligations.

## 8. Bar-Natan Dotted Calculus RAW DOUBLE-DOUBLE (`BarNatan/DottedCobordism.hs`)

* Full **cobordism category**: objects `Circles=Nat` (0 = ∅), morphisms `Cob` `BarNatan/DottedCobordism.hs:40` with `Compose`/`Tensor`/`Sum`/`Scale`, `src/tgt` `BarNatan/DottedCobordism.hs:70`.
* **BN1-BN6** `BarNatan/DottedCobordism.hs:103` are the defining relations of the category: spheres `S²=0`, `S²·=1`, neck-cutting `Saddle = Death⊗Birth - DotDeath⊗DotBirth`, delooping `Circle≃∅⊕∅[1]`, dot migration = Frobenius. Each stated as `eval ... ==. ... *** QED`.
* `eval` `BarNatan/DottedCobordism.hs:147` + `Saddle` desugars to neck-cutting; `hcomp/vcomp` `BarNatan/DottedCobordism.hs:201` gives double-category structure (`assocH/V`).
* `matrixOf` `BarNatan/DottedCobordism.hs:223` — the *universal TQFT* : any cobordism is a matrix over `Z` factoring through `A`. Identities `idLeft/idRight/scaleZero/sumComm/tensorId` `BarNatan/DottedCobordism.hs:270` seal the category laws.

## 9. Pure Functor `F: Cob → Vect_Z` (`TQFT/Functor.hs`)

* `F_obj n = A^{⊗n}` `TQFT/Functor.hs:34`, `F_mor` `TQFT/Functor.hs:40` lifts `eval` to linear combos with `normalise` (collect + sum). `src/tgt` `TQFT/Functor.hs:67`.
* **Functor laws** `TQFT/Functor.hs:86` : `F_id` (`F(Id)=id`), `F_comp` (`F(f∘g)=F f∘F g`), `F_sum` — pure, SMT-checked.
* `KhGen/dTQFT/d` `TQFT/Functor.hs:106` rebuilds Khovanov *via the functor*: `dTQFT` picks `Merge/Split` cobordism per `pos` and evaluates it; `homology` `TQFT/Functor.hs:134` = `cycles / boundaries` via `appears`.
* **Deep homology theorems**: `categorification` (`eulerChar∘homology = eulerChar`), `inducedHom`/`homologyFunctor` `TQFT/Functor.hs:154` (cobordism-induced maps respect composition), `SES`/`connecting` (long exact sequence), `Page`/`turnPage` (spectral sequence skeleton) `TQFT/Functor.hs:173` — the functor unlocks functoriality, LES, and SS for Khovanov.


## 10. Compilation Pipeline (Deterministic Transitions)

* **7 stages** `pipeline.lp:9` — `topos_dsl` (DSL grammar `valid_topos_syntax`), `classical_dataflow` (AST/BraidWord), `quantum_circuit` (YB verified), `quantum_ir` (fusion path + `pentagon_equation_holds`), branching to `simulator_input`/`optimizer_input`, `reduce` (YB + `entropy_reduced`), `hardware_mapping` (pulse sequence).
* **Plasma gates:** entropy `≤0.20` at every transition `pipeline.lp:68`, `T_pulse ≤ TauMin - 0.001` ties directly to `timing.lp:41` (`tau_poison_min(Lambda,TauMin) :- TauMin > 0.15/Lambda`). Violations are integrity constraints (`:-`).
* **Semantic equivalence** `equivalent(S1,S2) :- transition(S1,_,S2,_), semantic_preserved` preserves meaning through the pipeline — the pipeline is a refinement of the FSA, not a separate system.

## 11. Future Formalization Path


* Replace placeholder `ybRewrite` with a proper permutation of `Over/Under` and add `Reidemeister I` (`Tw` normalization).
* Implement `parseSurface` as a Parsec/Megaparsec recursive descent for the `braid { ... }` syntax; generate both Haskell `Braid` and Datalog `word/2` facts from the same parse.
* Lift ASP `transition/4` into a timed automaton (e.g., UPPAAL) to verify `T_reset < τ_poison` as a property, not just an arithmetic bound.
* Certify `jones` against the bracket polynomial definition in Lean4 — current implementation is a simplified state-sum; the Spec test suite pins writhe/linking invariants as regression guards.
