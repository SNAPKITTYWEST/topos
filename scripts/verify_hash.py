import pathlib, hashlib, re, json

root = pathlib.Path('topos')
mf = json.loads((root/'docs/NODE_MANIFEST.json').read_text(encoding='utf-8'))
for node in mf['nodes']:
    rel=node['file']
    fp=root/rel
    if not fp.exists():
        continue
    text=fp.read_text(encoding='utf-8')
    m=re.search(r'Source-Hash:\s*sha256:([a-f0-9]+)', text)
    header_hash = m.group(1) if m else 'none'
    manifest_hash = node['sha256']
    if 'FRAGMENT BINDING' in text:
        idx = text.find('======================================================================== */')
        if idx!=-1:
            after = text[idx+len('======================================================================== */'):].lstrip('\n')
            computed = hashlib.sha256(after.encode('utf-8')).hexdigest()
            match = 'OK' if computed==header_hash==manifest_hash else 'MISMATCH'
            print(f"{rel}: header {header_hash[:12]} manifest {manifest_hash[:12]} computed {computed[:12]} {match} len_after {len(after)}")
        else:
            print(f"{rel}: no header end")
    else:
        print(f"{rel}: no covenant")
