import pathlib
p = pathlib.Path('topos/README.md')
t = p.read_text(encoding='utf-8')
# Add node to Chinese table
old_row = "| `TOPOS-FILE-016-Architecture` | `docs/architecture.md` | 架構、十重YB等價性 | SL-AGPL3-001 / MGPLv3 |"
new_row = "| `TOPOS-FILE-016-Architecture` | `docs/architecture.md` | 架構、十重YB等價性 | SL-AGPL3-001 / MGPLv3 |\n| `TOPOS-FILE-017-Pipeline` | `prolog/pipeline.lp` | 編譯管線確定性狀態轉換、熵限、τ中毒閘 | SL-AGPL3-001 / MGPLv3 |"
if old_row in t and "TOPOS-FILE-017-Pipeline" not in t:
    t = t.replace(old_row, new_row)
    print("updated Chinese table")
else:
    print("Chinese table already or not found")

# Update combined view bullet? Keep but add pipeline mention? Combined view English already lists TQFT etc., we should add pipeline to spec bullet
if "prolog/pipeline.lp" not in t:
    # Find spec bullet
    old = "* **Spec:** `prolog/*.lp` + `datalog/*.dl` (declarative)"
    new = "* **Spec:** `prolog/*.lp` (`state_machine`, `timing`, `pipeline`) + `datalog/*.dl` (declarative)"
    if old in t:
        t = t.replace(old, new)
        print("updated spec bullet")

# Add layout entry for pipeline
old_layout = "├── prolog/timing.lp               # reset latency"
new_layout = "├── prolog/timing.lp               # reset latency\n├── prolog/pipeline.lp             # compilation pipeline (7 stages, entropy ≤0.20, τ_poison-gated)"
if old_layout in t and "pipeline.lp" not in t.split("prolog/timing.lp")[1].split("\n")[0]:
    # need check not already
    if "prolog/pipeline.lp" not in t:
        t = t.replace(old_layout, new_layout)
        print("updated layout")

# Add section 12 before Combined View
section_12 = """
### 12. Compilation Pipeline — Deterministic Transitions (`prolog/pipeline.lp`)

7-stage plasma-gate enforced pipeline grounded in Topos formal verification:

* **Stages:** `topos_dsl → classical_dataflow → quantum_circuit → quantum_ir → {simulator_input, optimizer_input} → hardware_mapping` `pipeline.lp:9`
* **Transitions (entropy-costed):** `parse 0.00` → `elaborate 0.01` (YB verified) → `encode 0.02` (pentagon via `f_matrix_consistent`) → `branch 0.005` → `reduce 0.015` (YB + entropy_reduced) → `map_hw Entropy≤0.20` with `T_pulse ≤ TauMin - 0.001` (`tau_poison_min` from ENKI) `pipeline.lp:19`
* **Global gates:** `:- E>0.20` (entropy never exceeds) `pipeline.lp:68`, `:- not tau_poison_satisfied` for `hardware_mapping`, `equivalent(S1,S2)` preserves semantics
* **Optimization:** `#minimize` total entropy + unverified stages `pipeline.lp:82`

Links the earlier FSA (`state_machine.lp`) and timing (`timing.lp:41` `tau_poison_min`) to the braid stack — hardware mapping is strictly `τ_poison`-gated.

"""

marker = "---\n\n### Combined View"
if section_12.strip() not in t and marker in t:
    t = t.replace(marker, section_12 + marker)
    print("added section 12")

# Also add quickstart for pipeline asp?
if "clingo prolog/pipeline.lp" not in t:
    old_qs = "clingo prolog/timing.lp"
    new_qs = "clingo prolog/timing.lp\nclingo prolog/pipeline.lp"
    if old_qs in t:
        t = t.replace(old_qs, new_qs)
        print("added pipeline to quickstart")

p.write_text(t, encoding='utf-8')
print("README updated")

# Update architecture.md
arch = pathlib.Path('topos/docs/architecture.md')
at = arch.read_text(encoding='utf-8')
if "pipeline.lp" not in at:
    sec = """
## 10. Compilation Pipeline (Deterministic Transitions)

* **7 stages** `pipeline.lp:9` — `topos_dsl` (DSL grammar `valid_topos_syntax`), `classical_dataflow` (AST/BraidWord), `quantum_circuit` (YB verified), `quantum_ir` (fusion path + `pentagon_equation_holds`), branching to `simulator_input`/`optimizer_input`, `reduce` (YB + `entropy_reduced`), `hardware_mapping` (pulse sequence).
* **Plasma gates:** entropy `≤0.20` at every transition `pipeline.lp:68`, `T_pulse ≤ TauMin - 0.001` ties directly to `timing.lp:41` (`tau_poison_min(Lambda,TauMin) :- TauMin > 0.15/Lambda`). Violations are integrity constraints (`:-`).
* **Semantic equivalence** `equivalent(S1,S2) :- transition(S1,_,S2,_), semantic_preserved` preserves meaning through the pipeline — the pipeline is a refinement of the FSA, not a separate system.

## 11. Future Formalization Path
"""
    # Replace future header
    if "## 10. Future Formalization Path" in at:
        at = at.replace("## 10. Future Formalization Path", sec)
        print("added arch pipeline section")
    elif "## 11. Future" not in at:
        # fallback
        at = at.replace("## 10. Future", sec)
    arch.write_text(at, encoding='utf-8')
    print("arch updated")
else:
    print("arch already has pipeline")

# Update cabal
cabal = pathlib.Path('topos/topos.cabal')
ct = cabal.read_text(encoding='utf-8')
if "prolog/pipeline.lp" not in ct:
    ct = ct.replace("prolog/timing.lp", "prolog/timing.lp\n                    prolog/pipeline.lp")
    cabal.write_text(ct, encoding='utf-8')
    print("cabal updated")
else:
    print("cabal already")
