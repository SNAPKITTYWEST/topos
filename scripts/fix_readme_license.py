import pathlib
p = pathlib.Path('topos/README.md')
t = p.read_text(encoding='utf-8')
old = "## License\n\nMIT — see `LICENSE`."
new = """## License

**Sovereign Leviathan Covenant — SL-AGPL3-001 / MGPLv3** (AGPLv3 + Sovereign Leviathan additional terms, England & Wales) — see `LICENSE`.

Each file carries `/* SOVEREIGN LEVIATHAN COVENANT — FRAGMENT BINDING */` with `Node-ID`, `Source-Hash`, `License-ID: SL-AGPL3-001`, `Covenant-Version: 1.0` — see `docs/NODE_MANIFEST.json` and `docs/PROVENANCE.md`.

Governing law: England and Wales. English controlling; العربية and 中文 co-equal."""
if old in t:
    t = t.replace(old, new)
    p.write_text(t, encoding='utf-8')
    print("fixed README license")
else:
    print("not found old")
    # try alternative
    if "MIT — see `LICENSE`." in t:
        t = t.replace("MIT — see `LICENSE`.", "**Sovereign Leviathan Covenant — SL-AGPL3-001 / MGPLv3** (AGPLv3 + Sovereign Leviathan additional terms, England and Wales) — see `LICENSE`.\n\nEach file carries `/* SOVEREIGN LEVIATHAN COVENANT — FRAGMENT BINDING */` with `Node-ID`, `Source-Hash`, `License-ID: SL-AGPL3-001`, `Covenant-Version: 1.0` — see `docs/NODE_MANIFEST.json` and `docs/PROVENANCE.md`.")
        p.write_text(t, encoding='utf-8')
        print("fixed alternative")
