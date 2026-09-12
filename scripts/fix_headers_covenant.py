import pathlib, json, hashlib

root = pathlib.Path('topos')
mf_path = root / 'docs/NODE_MANIFEST.json'
data = json.loads(mf_path.read_text(encoding='utf-8'))

# Also need to handle topos.cabal, LICENSE etc not in manifest? LICENSE not in manifest, but we replaced LICENSE already, so skip.
# For each node in manifest, fix its file header to canonical /* FRAGMENT BINDING */

def strip_old_header(text):
    # If contains SOVEREIGN LEVIATHAN COVENANT - FRAGMENT BINDING, strip up to second ===========================================================;
    if "SOVEREIGN LEVIATHAN COVENANT - FRAGMENT BINDING" not in text:
        return text
    lines = text.splitlines()
    # Find lines containing ===========================================================
    indices = [i for i,l in enumerate(lines) if "===========================================================" in l]
    if len(indices) >= 2:
        cut = indices[1] + 1
        # also skip following blank line if exists
        # Also need to skip the second block's header lines? Actually old header had two blocks: first covenant + 32 lines, second node key block.
        # Our stripping should remove up to second occurrence + 1 line after? Let's include one extra line after cut if blank
        if cut < len(lines) and lines[cut].strip() == "":
            cut += 1
        # But old header after second block also had no extra blank? The remaining content after header should start after cut.
        # However there may be trailing blank lines, let strip one more.
        return "\n".join(lines[cut:]).lstrip("\n")
    # fallback: try to find LICENSE and cut after See LICENSE
    if "License-Location: LICENSE;" in text:
        idx = text.find("License-Location: LICENSE;")
        # find end of line
        eol = text.find("\n", idx)
        # find next ===========================================================;
        nxt = text.find("===========================================================", eol)
        if nxt != -1:
            eol2 = text.find("\n", nxt)
            if eol2 != -1:
                return text[eol2+1:].lstrip("\n")
    return text

# New canonical header template
template = """/* ========================================================================
 * SOVEREIGN LEVIATHAN COVENANT — FRAGMENT BINDING
 * ========================================================================
 *
 * License-ID:        SL-AGPL3-001
 * Covenant-Version:  1.0
 * Node-ID:           {node_id}
 * Parent-Covenant:   SL-AGPL3-001
 * Copyright:         2026 SNAPKITTYWEST
 * Source-Hash:       sha256:{sha}
 *
 * This file is governed by the GNU Affero General Public License,
 * version 3, together with the applicable Sovereign Leviathan
 * additional terms identified by this notice.
 *
 * Hark, though this node be but a spark,
 * Its covenant endureth through the dark.
 *
 * Lex in solido: the applicable license governs the covered work
 * according to its actual terms and applicable law.
 *
 * Ignorantia juris non excusat.
 *
 * ======================================================================== */
"""

for node in data['nodes']:
    rel = node['file']
    node_id = node['nodeId']
    sha = node['sha256']
    fp = root / rel
    if not fp.exists():
        print(f"skip missing {rel}")
        continue
    content = fp.read_text(encoding='utf-8')
    # Strip old header
    original = strip_old_header(content)
    # If stripping didn't change and file still has old COMMENT style at top, we stripped correctly; else keep original as is but ensure we don't double-add
    # Check if original still starts with SOVEREIGN... then stripping failed, try more aggressive
    if original.startswith("/* ========================================================================"):
        # already has new canonical header, skip
        print(f"already canonical {rel}")
        continue
    if "SOVEREIGN LEVIATHAN COVENANT" in original[:500] and "FRAGMENT BINDING" in original[:500]:
        # still has covenant after strip, strip again
        original = strip_old_header(original)
    new_header = template.format(node_id=node_id, sha=sha)
    new_content = new_header + "\n" + original.lstrip("\n")
    fp.write_text(new_content, encoding='utf-8')
    print(f"fixed {rel} -> {node_id} sha {sha[:12]}...")

# Also fix topos.cabal and docs/architecture.md and others not in manifest? They are in manifest, so done.
# Fix LICENSE already done, no need header for LICENSE (license file itself not node?) but covenant says all source files, LICENSE is not source.

# Fix README.md separately: it has bilingual content but also had old header with <!-- COMMENT --> style. Our strip should have removed old header, but we need to ensure new canonical header is added as /* block */ not HTML comment.
# For README, the header we just added is /* ... */ which in markdown will be visible as text, not comment. That's according to spec (/* ... */ is the header). It's okay.
# But we should verify README still has Chinese top after header.

# Also fix docs/architecture.md etc already handled via manifest.

print("done")
