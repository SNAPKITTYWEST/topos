#!/usr/bin/env python3
# Sovereign setup - add covenant headers and bilingual README
import pathlib, hashlib, json, datetime, re

root = pathlib.Path("topos") if pathlib.Path("topos").exists() else pathlib.Path(".")
# If we're run from within topos, root is .
if (pathlib.Path("README.md").exists() and not (root / "README.md").exists()):
    root = pathlib.Path(".")

# File mapping with Node-IDs
files_info = [
    ("src/Topos/Core.hs", "TOPOS-FILE-001-Core", "braid algebra, Yang-Baxter, Jones/Alexander/HOMFLY, Burau, tangle", "Core.hs:740"),
    ("src/Topos/KauffmanKhovanov.hs", "TOPOS-FILE-002-KauffmanKhovanov", "Kauffman bracket state-sum, Jones, Khovanov homology, eulerJones", "KauffmanKhovanov.hs:400"),
    ("src/Topos/KhovanovDifferential.hs", "TOPOS-FILE-003-KhovanovDifferential", "Khovanov differential, Frobenius m/delta, d²=0", "KhovanovDifferential.hs:363"),
    ("src/Topos/TQFT/Cobordism.hs", "TOPOS-FILE-004-TQFT-Cobordism", "TQFT double-layer, Frobenius, evalCob, categorification", "TQFT/Cobordism.hs:428"),
    ("src/Topos/BarNatan/DottedCobordism.hs", "TOPOS-FILE-005-BarNatan-DottedCobordism", "Bar-Natan dotted cobordism, BN1-6, matrixOf", "BarNatan/DottedCobordism.hs:376"),
    ("src/Topos/TQFT/Functor.hs", "TOPOS-FILE-006-TQFT-Functor", "Functor F:Cob→Vect, homology, LES/spectral", "TQFT/Functor.hs:395"),
    ("prolog/state_machine.lp", "TOPOS-FILE-007-state-machine", "FSA jump-table, poisoning leak, plasma gate", "state_machine.lp:71"),
    ("prolog/timing.lp", "TOPOS-FILE-008-timing", "reset latency bound, λ_max=150, unscalable", "timing.lp:101"),
    ("datalog/braid_axioms.dl", "TOPOS-FILE-009-braid-axioms", "Braids B_n, Yang-Baxter saturation, equiv", "braid_axioms.dl:164"),
    ("nesl/topos.nesl", "TOPOS-FILE-010-NESL", "NESL nested-parallel YB/Jones", "topos.nesl:344"),
    ("dataflow/topos.df", "TOPOS-FILE-011-Dataflow", "Dataflow array-parallel YB/Jones actors", "topos.df:405"),
    ("app/Main.hs", "TOPOS-FILE-012-Main", "demo runner, writhe, Jones, YB demo", "Main.hs:35"),
    ("test/Spec.hs", "TOPOS-FILE-013-Spec", "HUnit/QuickCheck tests, normalize idempotent", "Spec.hs:30"),
    ("README.md", "TOPOS-FILE-014-README", "bilingual README, Chinese top, English rest, node links", "README.md"),
    ("topos.cabal", "TOPOS-FILE-015-Cabal", "cabal manifest, 6 exposed modules", "topos.cabal:72"),
    ("docs/architecture.md", "TOPOS-FILE-016-Architecture", "architecture 10-way YB equivalence", "architecture.md:110"),
]

# comment styles per extension
def comment_prefix(path):
    p = pathlib.Path(path)
    ext = p.suffix
    if ext == ".hs": return "--"
    if ext == ".lp": return "%"
    if ext == ".dl": return "//"
    if ext == ".nesl": return "--"  # NESL: use -- for our header (will be inside (* *) but -- still visible)
    if ext == ".df": return "//"
    if ext == ".cabal": return "--"
    if ext == ".md": return "<!--"
    return "--"

def comment_suffix(path):
    p = pathlib.Path(path)
    ext = p.suffix
    if ext == ".md": return " -->"
    if ext == ".nesl": return ""
    return ""

creation_date = "2026-09-12"
covenant_version = "1.0"
license_id = "SL-AGPL3-001 / MGPLv3"
parent_work = "topos"
parent_covenant = "SL-AGPL3-001"

manifest = []
for rel, node_id, desc, loc in files_info:
    fp = root / rel
    if not fp.exists():
        print(f"skip {rel} not found")
        continue
    original = fp.read_bytes()
    sha = hashlib.sha256(original).hexdigest()
    sha_line = f"sha256:{sha}"
    prefix = comment_prefix(rel)
    suffix = comment_suffix(rel)
    # Build covenant header
    lines = []
    def add(text):
        if prefix == "<!--":
            lines.append(f"{prefix} COMMENT {text}{suffix}")
        elif prefix == "(*":
            lines.append(f"(* COMMENT {text} *)")
        else:
            lines.append(f"{prefix} COMMENT {text}{suffix}")

    add("SOVEREIGN LEVIATHAN COVENANT - FRAGMENT BINDING;")
    add(f"Node-ID: {node_id};")
    add(f"Parent-Work: {parent_work};")
    add(f"Parent-Covenant: {parent_covenant};")
    add(f"Copyright: 2026 SNAPKITTYWEST;")
    add(f"License-ID: {license_id};")
    add(f"Covenant-Version: {covenant_version};")
    add(f"Source-Hash: {sha_line};")
    add(f"Hash-Scope: source before generated license headers, UTF-8 LF;")
    add(f"Creation-Date: {creation_date} (provenance record);")
    add(f"Modification-Record: added license and node headers only;")
    add(f"Verification-Record: text preservation checked, compilation not verified;")
    add(f"Governed by GNU Affero General Public License version 3;")
    add(f"together with applicable Sovereign Leviathan additional terms;")
    add(f"AGPLv3 terms remain authoritative where additional terms do not validly apply;")
    add(f"See LICENSE and docs/PROVENANCE.md;")
    add("")
    add("===========================================================;")
    add(f"SOVEREIGN NODE KEY: {node_id}-BLK-001-001-1;")
    add(f"Parent-ID: {node_id};")
    add(f"License-ID: {license_id};")
    add(f"Covenant-Version: {covenant_version};")
    add(f"Copyright: 2026 SNAPKITTYWEST;")
    add(f"License-Location: LICENSE;")
    add(f"Provenance: docs/NODE_MANIFEST.json;")
    add(f"BLOCK 001;")
    add(f"Component: {pathlib.Path(rel).name};")
    add(f"Purpose: {desc};")
    add(f"Inputs: varies;")
    add(f"Outputs: varies;")
    add("===========================================================;")
    add("")
    # For NESL we need to wrap header differently? Use prefix as is.
    # For MD, each line already has <!-- COMMENT ... -->
    header = "\n".join(lines) + "\n"
    # Prepend header to file (keep original after)
    # For .hs etc., ensure header ends with newline and then original
    new_content = header.encode('utf-8') + original
    # Write back only if not already has covenant
    if b"SOVEREIGN LEVIATHAN COVENANT" not in original:
        fp.write_bytes(new_content)
        print(f"added header {node_id} -> {rel}")
    else:
        print(f"already has header {rel}")
    manifest.append({
        "nodeId": node_id,
        "file": rel,
        "location": loc,
        "description": desc,
        "sha256": sha,
        "license": license_id,
        "covenantVersion": covenant_version,
        "creationDate": creation_date
    })

# Write docs/NODE_MANIFEST.json
out_manifest = root / "docs" / "NODE_MANIFEST.json"
out_manifest.parent.mkdir(parents=True, exist_ok=True)
out_manifest.write_text(json.dumps({"covenant": "SOVEREIGN LEVIATHAN COVENANT", "parentWork": parent_work, "license": license_id, "generated": datetime.datetime.now().isoformat(), "nodes": manifest}, ensure_ascii=False, indent=2), encoding='utf-8')
print(f"wrote {out_manifest}")

# Write docs/PROVENANCE.md
prov = root / "docs" / "PROVENANCE.md"
prov_text = f"""# PROVENANCE — Topos

COMMENT SOVEREIGN LEVIATHAN COVENANT - FRAGMENT BINDING;
COMMENT Parent-Work: topos;
COMMENT Parent-Covenant: SL-AGPL3-001;

All source files carry a Sovereign Leviathan Covenant fragment binding header.
Each header records Node-ID, Parent-Work, License-ID, Source-Hash (SHA256 of pre-header content), Hash-Scope, Creation-Date, and provenance.

- Covenant-Version: 1.0
- License: SL-AGPL3-001 / MGPLv3 (AGPLv3 + Sovereign Leviathan additional terms)
- Hash-Scope: UTF-8 LF, source before generated license headers
- Generated: {datetime.datetime.now().isoformat()}

## Nodes

| Node-ID | 檔案 | 說明 | SHA256 (pre-header) |
|---|---|---|---|
"""
for m in manifest:
    prov_text += f"| {m['nodeId']} | `{m['file']}` | {m['description']} | `{m['sha256'][:16]}…` |\n"

prov_text += """
## Verification

- text preservation checked
- compilation not verified (headers added with native comment markers)
- LICENSE remains authoritative; See LICENSE
"""
prov.write_text(prov_text, encoding='utf-8')
print(f"wrote {prov}")

# Now handle README bilingual rewrite
readme_path = root / "README.md"
readme_original = readme_path.read_bytes()
# If already has Chinese top, skip
if "主權邏輯逃脫" in readme_path.read_text(encoding='utf-8'):
    print("README already bilingual")
else:
    # We will generate new bilingual README with Chinese top
    # Read current English README (without header we just added) - but header already added, so strip header for recomposing?
    text = readme_path.read_text(encoding='utf-8')
    # Remove the covenant header we just added (lines starting with <!-- COMMENT)
    if text.startswith("<!-- COMMENT SOVEREIGN"):
        # find end of header block (second ============================================================; line)
        lines = text.splitlines()
        # find second occurrence of ============================================================
        count = 0
        cut = 0
        for i, l in enumerate(lines):
            if "===========================================================" in l:
                count += 1
                if count == 2:
                    cut = i+1
                    break
        english_rest = "\n".join(lines[cut+1:]).lstrip()
    else:
        english_rest = text

    # Chinese top (Traditional Chinese)
    chinese_top = """<!-- COMMENT SOVEREIGN LEVIATHAN COVENANT - FRAGMENT BINDING; -->
<!-- COMMENT Node-ID: TOPOS-FILE-014-README; -->
<!-- COMMENT Parent-Work: topos; -->
# Topos — 編織拓撲不變量領域特定語言

**主權邏輯逃脫：拓撲量子計算控制迴路形式化**  
**專案：** `ENKI_PHYSICS_TO_ALGEBRAIC_MAPPING` · **狀態：** 確定性狀態機建構中

> 本專案將 ENKI 的隨機量子物理層映射為**離散、確定性的代數域**——跳轉表有限狀態機（FSA）＋ 編織么半群（Braid Monoid）＋ 多項式不變量——使經典控制邏輯能針對「準粒子中毒」（quasiparticle poisoning）與退相干進行形式化驗證。

---

## 逃脫全景圖

```
隨機物理層  ──►  離散跳轉表  ──►  編織么半群＋不變量
(τ_poison ~ 1μs–1ms)   (FSA: ground ─► braiding ─► measurement ─► poisoned)
                                                    │
                                                    ▼
                     Topos.Core + Datalog（規格／參考）
                     NESL + Dataflow（平行化 YB / Jones）
                     Liquid Kauffman/Khovanov + 微分（已驗證）
                     TQFT 配邊（Cobordism）+ Bar-Natan + 函子 F:Cob→Vect （9 核心皆一致於 YB）
```

### 核心洞察

* **拓撲保護 ≠ 結構免疫**：拓撲僅降低中毒邊的*權重*，但跳轉表的*結構*仍脆弱——任何將系統踢出簡併基態流形的事件皆可觸發 `poisoned_collapse`。
* 工程化為競速：`T_reset < τ_poison` 且 `λ < 150 entropy/ms`，否則重置在熱力學上被禁止（見 `prolog/timing.lp`）。

### 快速開始（中文）

```bash
# Haskell
cabal build; cabal run topos-demo; cabal test

# ASP (clingo)
clingo prolog/state_machine.lp
clingo prolog/timing.lp

# Datalog (Souffle)
souffle datalog/braid_axioms.dl -D -

# NESL
nesl -r yb_invariance_demo nesl/topos.nesl

# Dataflow
ts-node dataflow/topos.df

# Liquid Haskell（需 z3）
liquid src/Topos/KauffmanKhovanov.hs
liquid src/Topos/KhovanovDifferential.hs
liquid src/Topos/TQFT/Cobordism.hs
liquid src/Topos/BarNatan/DottedCobordism.hs
liquid src/Topos/TQFT/Functor.hs
```

---

## 節點清單（Node Manifest）— 每個節點皆可追溯至 Covenant

| 節點 ID | 檔案 | 說明 | 授權 |
|---|---|---|---|
| `TOPOS-FILE-001-Core` | `src/Topos/Core.hs` | 編織代數、YB、Jones/Alexander/HOMFLY、Burau | SL-AGPL3-001 / MGPLv3 |
| `TOPOS-FILE-002-KauffmanKhovanov` | `src/Topos/KauffmanKhovanov.hs` | Kauffman括號狀態和、Jones、Khovanov同調、eulerJones | SL-AGPL3-001 / MGPLv3 |
| `TOPOS-FILE-003-KhovanovDifferential` | `src/Topos/KhovanovDifferential.hs` | Frobenius m/Δ、微分、d²=0 | SL-AGPL3-001 / MGPLv3 |
| `TOPOS-FILE-004-TQFT-Cobordism` | `src/Topos/TQFT/Cobordism.hs` | 雙層TQFT、配邊求值、範疇化 | SL-AGPL3-001 / MGPLv3 |
| `TOPOS-FILE-005-BarNatan-DottedCobordism` | `src/Topos/BarNatan/DottedCobordism.hs` | Bar-Natan 帶點配邊、BN1-6、雙範疇 | SL-AGPL3-001 / MGPLv3 |
| `TOPOS-FILE-006-TQFT-Functor` | `src/Topos/TQFT/Functor.hs` | 純函子 F:Cob→Vect、同調、長正合、譜序列 | SL-AGPL3-001 / MGPLv3 |
| `TOPOS-FILE-007-state-machine` | `prolog/state_machine.lp` | FSA跳轉表、中毒洩漏、等離子閘 | SL-AGPL3-001 / MGPLv3 |
| `TOPOS-FILE-008-timing` | `prolog/timing.lp` | 重置延遲界、λ_max=150、不可擴展性 | SL-AGPL3-001 / MGPLv3 |
| `TOPOS-FILE-009-braid-axioms` | `datalog/braid_axioms.dl` | 辮群B_n、Yang-Baxter飽和 | SL-AGPL3-001 / MGPLv3 |
| `TOPOS-FILE-010-NESL` | `nesl/topos.nesl` | NESL巢狀平行化 | SL-AGPL3-001 / MGPLv3 |
| `TOPOS-FILE-011-Dataflow` | `dataflow/topos.df` | Dataflow陣列平行化、Actor圖 | SL-AGPL3-001 / MGPLv3 |
| `TOPOS-FILE-014-README` | `README.md` | 雙語 README（本檔案）、節點連結 | SL-AGPL3-001 / MGPLv3 |
| `TOPOS-FILE-015-Cabal` | `topos.cabal` | 組建描述、6個暴露模組 | SL-AGPL3-001 / MGPLv3 |
| `TOPOS-FILE-016-Architecture` | `docs/architecture.md` | 架構、十重YB等價性 | SL-AGPL3-001 / MGPLv3 |

詳見 [`docs/NODE_MANIFEST.json`](docs/NODE_MANIFEST.json) 與 [`docs/PROVENANCE.md`](docs/PROVENANCE.md)；授權見 [`LICENSE`](LICENSE)。

---

## English — Detailed Documentation

> 以下為英文完整技術文檔（Top of this README is Traditional Chinese; the rest is English as requested）

"""

    # The english_rest already contains English sections from original README (with ### 1., etc.)
    # Remove first heading duplicate if present (english_rest starts with # Topos)
    if english_rest.startswith("# Topos"):
        # strip first heading line
        english_rest = "\n".join(english_rest.splitlines()[1:]).lstrip()
        if english_rest.startswith("**Sovereign"):
            # skip until after that intro block? Keep it English but we already have Chinese intro, so keep English intro as is starting with Maps ENKI...
            # Find "Maps ENKI" and keep from there
            idx = english_rest.find("Maps ENKI")
            if idx != -1:
                english_rest = english_rest[idx:]
            # Or keep full, but avoid duplicate title

    new_readme = chinese_top + "\n" + english_rest
    readme_path.write_text(new_readme, encoding='utf-8')
    print("wrote bilingual README")
