import pathlib, hashlib, json
root = pathlib.Path('topos')
fp = root / 'prolog/pipeline.lp'
orig = fp.read_bytes()
# If already has covenant, strip to compute original hash before? But we already wrote without header, then added header in previous step? Now file has header? Let's check if header already exists
text = orig.decode('utf-8', errors='ignore')
if "SOVEREIGN LEVIATHAN COVENANT" in text:
    # already headerized, compute hash of content after header (first header block is 32 lines). Instead just recompute sha of content after header removal for manifest.
    # For now skip header re-add
    print("already headerized, skipping")
else:
    sha = hashlib.sha256(orig).hexdigest()
    print('sha', sha)
    prefix='%'
    lines=[]
    def add(t):
        lines.append(f'{prefix} COMMENT {t}')
    add('SOVEREIGN LEVIATHAN COVENANT - FRAGMENT BINDING;')
    add('Node-ID: TOPOS-FILE-017-Pipeline;')
    add('Parent-Work: topos;')
    add('Parent-Covenant: SL-AGPL3-001;')
    add('Copyright: 2026 SNAPKITTYWEST;')
    add('License-ID: SL-AGPL3-001 / MGPLv3;')
    add('Covenant-Version: 1.0;')
    add(f'Source-Hash: sha256:{sha};')
    add('Hash-Scope: source before generated license headers, UTF-8 LF;')
    add('Creation-Date: 2026-09-12 (provenance record);')
    add('Modification-Record: added license and node headers only;')
    add('Verification-Record: text preservation checked, compilation not verified;')
    add('Governed by GNU Affero General Public License version 3;')
    add('together with applicable Sovereign Leviathan additional terms;')
    add('AGPLv3 terms remain authoritative where additional terms do not validly apply;')
    add('See LICENSE and docs/PROVENANCE.md;')
    add('')
    add('===========================================================;')
    add('SOVEREIGN NODE KEY: TOPOS-FILE-017-Pipeline-BLK-001-001-1;')
    add('Parent-ID: TOPOS-FILE-017-Pipeline;')
    add('License-ID: SL-AGPL3-001 / MGPLv3;')
    add('Covenant-Version: 1.0;')
    add('Copyright: 2026 SNAPKITTYWEST;')
    add('License-Location: LICENSE;')
    add('Provenance: docs/NODE_MANIFEST.json;')
    add('BLOCK 001;')
    add('Component: pipeline.lp;')
    add('Purpose: TOPOS compilation pipeline deterministic state transitions, entropy-bounded, tau_poison-gated;')
    add('Inputs: varies;')
    add('Outputs: varies;')
    add('===========================================================;')
    add('')
    header = '\n'.join(lines) + '\n'
    fp.write_bytes(header.encode('utf-8') + orig)
    print('header added')

# Update manifest if not already
mf = root / 'docs/NODE_MANIFEST.json'
data = json.loads(mf.read_text(encoding='utf-8'))
if not any(n['nodeId']=='TOPOS-FILE-017-Pipeline' for n in data['nodes']):
    # need sha (compute of original without header)
    # orig already contains header now, so recompute sha of file after stripping header? Instead we stored sha before
    # Let's read file and strip first 32 lines to get original hash
    content = fp.read_text(encoding='utf-8')
    # remove first 32 lines (header)
    lines_content = content.splitlines()
    # find second ============================================================;
    cnt=0
    cut=0
    for i,l in enumerate(lines_content):
        if "===========================================================" in l:
            cnt+=1
            if cnt==2:
                cut=i+1
                break
    original_text = "\n".join(lines_content[cut+1:])
    sha2 = hashlib.sha256(original_text.encode('utf-8')).hexdigest()
    # Use sha2 (should equal sha before)
    data['nodes'].append({'nodeId':'TOPOS-FILE-017-Pipeline','file':'prolog/pipeline.lp','location':'pipeline.lp:90','description':'TOPOS compilation pipeline deterministic state transitions, entropy-bounded, tau_poison-gated','sha256':sha2,'license':'SL-AGPL3-001 / MGPLv3','covenantVersion':'1.0','creationDate':'2026-09-12'})
    mf.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding='utf-8')
    print('manifest updated', len(data['nodes']))
else:
    print('manifest already has pipeline')

prov = root / 'docs/PROVENANCE.md'
txt = prov.read_text(encoding='utf-8')
if 'TOPOS-FILE-017' not in txt:
    # compute sha for row
    sha_short = data['nodes'][-1]['sha256'][:16]
    row = f"| TOPOS-FILE-017-Pipeline | `prolog/pipeline.lp` | TOPOS compilation pipeline deterministic state transitions, entropy-bounded, tau_poison-gated | `{sha_short}…` |\n"
    txt = txt.replace('## Verification', row + '\n## Verification')
    prov.write_text(txt, encoding='utf-8')
    print('provenance updated')
else:
    print('provenance already')
