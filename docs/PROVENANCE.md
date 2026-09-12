# PROVENANCE — Topos

COMMENT SOVEREIGN LEVIATHAN COVENANT - FRAGMENT BINDING;
COMMENT Parent-Work: topos;
COMMENT Parent-Covenant: SL-AGPL3-001;

All source files carry a Sovereign Leviathan Covenant fragment binding header.
Each header records Node-ID, Parent-Work, License-ID, Source-Hash (SHA256 of pre-header content), Hash-Scope, Creation-Date, and provenance.

- Covenant-Version: 1.0
- License: SL-AGPL3-001 / MGPLv3 (AGPLv3 + Sovereign Leviathan additional terms)
- Hash-Scope: UTF-8 LF, source before generated license headers
- Generated: 2026-09-12T03:15:36.675340

## Nodes

| Node-ID | 檔案 | 說明 | SHA256 (pre-header) |
|---|---|---|---|
| TOPOS-FILE-001-Core | `src/Topos/Core.hs` | braid algebra, Yang-Baxter, Jones/Alexander/HOMFLY, Burau, tangle | `6fd5bd22fb0ba872…` |
| TOPOS-FILE-002-KauffmanKhovanov | `src/Topos/KauffmanKhovanov.hs` | Kauffman bracket state-sum, Jones, Khovanov homology, eulerJones | `0161605ee5918010…` |
| TOPOS-FILE-003-KhovanovDifferential | `src/Topos/KhovanovDifferential.hs` | Khovanov differential, Frobenius m/delta, d²=0 | `e3212ad5cc2d78f9…` |
| TOPOS-FILE-004-TQFT-Cobordism | `src/Topos/TQFT/Cobordism.hs` | TQFT double-layer, Frobenius, evalCob, categorification | `49609b59ff031a9a…` |
| TOPOS-FILE-005-BarNatan-DottedCobordism | `src/Topos/BarNatan/DottedCobordism.hs` | Bar-Natan dotted cobordism, BN1-6, matrixOf | `2036d93295268ea1…` |
| TOPOS-FILE-006-TQFT-Functor | `src/Topos/TQFT/Functor.hs` | Functor F:Cob→Vect, homology, LES/spectral | `367bc1e6b856d4e8…` |
| TOPOS-FILE-007-state-machine | `prolog/state_machine.lp` | FSA jump-table, poisoning leak, plasma gate | `722595a09a77d253…` |
| TOPOS-FILE-008-timing | `prolog/timing.lp` | reset latency bound, λ_max=150, unscalable | `a47dff3400b2cdbb…` |
| TOPOS-FILE-009-braid-axioms | `datalog/braid_axioms.dl` | Braids B_n, Yang-Baxter saturation, equiv | `f70acc9875c8fc7d…` |
| TOPOS-FILE-010-NESL | `nesl/topos.nesl` | NESL nested-parallel YB/Jones | `1e36b13ee778ad1f…` |
| TOPOS-FILE-011-Dataflow | `dataflow/topos.df` | Dataflow array-parallel YB/Jones actors | `b25b8f2999582898…` |
| TOPOS-FILE-012-Main | `app/Main.hs` | demo runner, writhe, Jones, YB demo | `e862678480134258…` |
| TOPOS-FILE-013-Spec | `test/Spec.hs` | HUnit/QuickCheck tests, normalize idempotent | `0e5803eed612d8a3…` |
| TOPOS-FILE-014-README | `README.md` | bilingual README, Chinese top, English rest, node links | `cd8b51679e414940…` |
| TOPOS-FILE-015-Cabal | `topos.cabal` | cabal manifest, 6 exposed modules | `86e850b57f145b72…` |
| TOPOS-FILE-016-Architecture | `docs/architecture.md` | architecture 10-way YB equivalence | `18f94c97566beb85…` |

| TOPOS-FILE-017-Pipeline | `prolog/pipeline.lp` | TOPOS compilation pipeline deterministic state transitions, entropy-bounded, tau_poison-gated | `34c5dcbd9a8d1fd9…` |

## Verification

- text preservation checked
- compilation not verified (headers added with native comment markers)
- LICENSE remains authoritative; See LICENSE
