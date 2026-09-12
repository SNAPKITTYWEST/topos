import pathlib, re

p = pathlib.Path('topos/README.md')
t = p.read_text(encoding='utf-8')

# Find Quickstart to Formal Gap block
m = re.search(r'## Quickstart.*?(?=## Formal Gap)', t, re.DOTALL)
if not m:
    print("not found Quickstart to Formal Gap")
    exit(1)

old = m.group(0)

new = """## Quickstart — Flowcharts (not slop)

> **From this point down — flowcharts, not slop.** Each stage is a deterministic transition with plasma-gate entropy ≤0.20 and `τ_poison` gating — runnable via the commands embedded in the charts.

### 0. Overall — `prolog/pipeline.lp` (7 stages)

```mermaid
graph LR
  A[topos_dsl<br/>`valid_topos_syntax`] -->|parse<br/>0.00| B[classic_dataflow<br/>AST]
  B -->|elaborate<br/>0.01<br/>YB verified| C[quantum_circuit<br/>BraidWord]
  C -->|encode<br/>0.02<br/>pentagon| D[quantum_ir<br/>FusionPath]
  D -->|branch_sim<br/>0.005| E[simulator_input]
  D -->|branch_opt<br/>0.005| F[optimizer_input]
  F -->|reduce<br/>0.015<br/>YB + entropy_reduced| F
  F -->|map_hw<br/>≤0.20<br/>T_pulse ≤ TauMin-0.001| G[hardware_mapping<br/>PulseSeq]
  G -.->|τ_poison_min<br/>TauMin >0.15/λ| H{PLASMA GATE<br/>E≤0.20}
  style H fill:#ffcccc,stroke:#cc0000
```

*Renders the ASP pipeline: `stage/1` + `transition/4` + `tau_poison_min/2` → hardware mapping is strictly `τ_poison`-gated.*

### 1. Haskell — `Topos.Core` + Liquid (`src/Topos/`)

```mermaid
graph TD
  H1[cabal build<br/>GHC ≥9.2] --> H2[cabal run topos-demo<br/>writhe/Jones/YB]
  H2 --> H3[cabal test<br/>HUnit + QuickCheck<br/>normalize idempotent]
  H3 --> H4[liquid<br/>KauffmanKhovanov.hs<br/>bracketYB/eulerJones]
  H4 --> H5[liquid<br/>KhovanovDifferential.hs<br/>dSquaredZero]
  H5 --> H6[liquid<br/>TQFT/Cobordism.hs<br/>dSquared/categorification]
  H6 --> H7[liquid<br/>BarNatan/DottedCobordism.hs<br/>BN1-6]
  H7 --> H8[liquid<br/>TQFT/Functor.hs<br/>F_id/F_comp]
```

```bash
cabal build
cabal run topos-demo
cabal test
liquid src/Topos/KauffmanKhovanov.hs       # bracketYB, jonesYB
liquid src/Topos/KhovanovDifferential.hs   # dSquaredZero
liquid src/Topos/TQFT/Cobordism.hs         # dSquared
liquid src/Topos/BarNatan/DottedCobordism.hs
liquid src/Topos/TQFT/Functor.hs
```

### 2. ASP — `prolog/*.lp` (clingo)

```mermaid
graph LR
  P1[state_machine.lp<br/>FSA + poisoning 0.20] --> P2[clingo<br/>stable model<br/>plasma gate]
  P3[timing.lp<br/>λ_max=150<br/>unscalable] --> P2
  P4[pipeline.lp<br/>7 stages<br/>E≤0.20] --> P2
```

```bash
clingo prolog/state_machine.lp   # valid_transition / invalid_op
clingo prolog/timing.lp          # valid_reset_sequence / unscalable(150)
clingo prolog/pipeline.lp        # pipeline stage validation + #minimize
```

### 3. Datalog — `datalog/braid_axioms.dl` (Souffle)

```mermaid
graph LR
  D1[braid_axioms.dl<br/>B_n: far-commute/YB/inverse] --> D2[souffle<br/>saturation]
  D2 --> D3[equiv lhs rhs<br/>σ₁σ₂σ₁ ≡ σ₂σ₁σ₂]
  D3 --> D4[YB key axiom<br/>equiv_word w_lhs w_rhs]
```

```bash
souffle datalog/braid_axioms.dl -D -
# souffle --output equiv --program braid_axioms.dl
# ?- equiv(\"lhs\",\"rhs\").  # → true
```

### 4. NESL — `nesl/topos.nesl` (nested parallel)

```mermaid
graph TD
  N1[topos.nesl<br/>Strand=int<br/>Laurent=[(exp,coeff)]] --> N2[is_yb_window / yb_rewrite]
  N2 --> N3[apply_yb_once<br/>sliding window]
  N3 --> N4[normalize_yb<br/>fixpoint]
  N4 --> N5[bracket_word<br/>reduce mul_laurent]
  N5 --> N6[batch_jones<br/>yb_invariance_demo<br/>lhs vs rhs]
```

```bash
nesl -r yb_invariance_demo nesl/topos.nesl  # → (j_lhs, j_rhs, true)
nesl -r invariance_suite nesl/topos.nesl
```

### 5. Dataflow — `dataflow/topos.df` (array/stream)

```mermaid
graph LR
  F1[topos.df<br/>Arr/Stream/Token] --> F2[Crossing/Twist/Compose<br/>Actors]
  F2 --> F3[YBWindowActor<br/>buf 3 + FreeReduce]
  F3 --> F4[Bracket/Writhe/Jones<br/>Add/Mul/Scale Laur]
  F4 --> F5[build_yb_invariance_graph<br/>LHS vs RHS]
  F5 --> F6[batch_normalize<br/>batch_jones<br/>assert_yb_invariance]
```

```bash
ts-node dataflow/topos.df  # build_yb_invariance_graph + assert_yb_invariance()
# → true  (sparse polys equal)
```

---

"""

# Replace
t_new = t.replace(old, new)
p.write_text(t_new, encoding='utf-8')
print(f"replaced Quickstart {len(old)} -> {len(new)} chars")
print("done")
