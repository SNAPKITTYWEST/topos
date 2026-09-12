import pathlib, hashlib, re, json

root = pathlib.Path('topos')
mf_path = root / 'docs/NODE_MANIFEST.json'
data = json.loads(mf_path.read_text(encoding='utf-8'))

for node in data['nodes']:
    rel = node['file']
    fp = root / rel
    if not fp.exists():
        continue
    text = fp.read_text(encoding='utf-8')
    if 'FRAGMENT BINDING' not in text:
        continue
    idx = text.find('======================================================================== */')
    if idx==-1:
        continue
    after = text[idx+len('======================================================================== */'):].lstrip('\n')
    computed = hashlib.sha256(after.encode('utf-8')).hexdigest()
    old_manifest = node['sha256']
    # Find header Source-Hash
    m = re.search(r'Source-Hash:\s*sha256:([a-f0-9]+)', text)
    header_hash = m.group(1) if m else 'none'
    if computed != old_manifest or computed != header_hash:
        print(f"{rel}: manifest {old_manifest[:12]} header {header_hash[:12]} computed {computed[:12]} -> updating")
        # update manifest
        node['sha256'] = computed
        # update header in file
        new_text = text.replace(f"Source-Hash:       sha256:{header_hash}", f"Source-Hash:       sha256:{computed}")
        fp.write_text(new_text, encoding='utf-8')
    else:
        print(f"{rel}: OK {computed[:12]}")

mf_path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding='utf-8')
print("manifest reconciled")

# Also update PROVENANCE.md rows
prov = root / 'docs/PROVENANCE.md'
pt = prov.read_text(encoding='utf-8')
for node in data['nodes']:
    nid = node['nodeId']
    # find row for this node and update short hash
    short = node['sha256'][:16]
    # replace existing row's hash
    # pattern: | NID | `file` | desc | `old…` |
    # we can use regex
    import re
    # Match row line for nid
    pattern = re.compile(r'(\| ' + re.escape(nid) + r' \| `[^`]+` \| [^|]+ \| `)[a-f0-9]+')
    pt_new, n = pattern.subn(r'\g<1>' + short, pt)
    if n>0:
        pt = pt_new
prov.write_text(pt, encoding='utf-8')
print("provenance updated")
