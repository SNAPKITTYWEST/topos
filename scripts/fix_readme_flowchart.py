import pathlib

p = pathlib.Path('topos/README.md')
t = p.read_text(encoding='utf-8')

# Find Quickstart section - it starts with Layout code block and then Quickstart
# We want to replace everything from "## Quickstart" down to "## Formal Gap" with flowchart version
# Let's locate markers

# The Quickstart header is likely "## Quickstart" or "Quickstart" in Chinese? Let's search
import re

# Find Layout block end and Quickstart start
# Layout ends with ``` then --- then Quickstart
old_quickstart = None
# Try to find the block from "## Quickstart" to "## Formal Gap"
m = re.search(r'## Quickstart.*?(?=## Formal Gap)', t, re.DOTALL)
if m:
    print("found Quickstart to Formal Gap", len(m.group(0)))
    old = m.group(0)
else:
    # Try alternative: search for "cabal build; cabal run" block
    m2 = re.search(r'```bash\ncabal build.*?(?=## Formal Gap)', t, re.DOTALL)
    if m2:
        print("found cabal block to Formal Gap")

# Instead, we will directly replace the Quickstart slop block that user highlighted:
# The block starts with "cabal build; cabal run topos-demo; cabal test" and ends before "---\n\n## 節點清單" ? But we already have Chinese node table before.
# Let's just locate the English Quickstart section header
# Search for "## Quickstart" or "Quickstart" Chinese? In current README after Layout, we have:
# ```
# topos/
# ...
# ```
# then ---
# then ## Quickstart
# Let's extract around

idx = t.find("## Quickstart")
if idx != -1:
    print("Quickstart at", idx)
    print(t[idx:idx+800][:800])
else:
    # search for "Quickstart" without ##
    idx = t.find("Quickstart")
    print("Quickstart generic at", idx)
    if idx!=-1:
        print(t[idx-200:idx+800])

# Also check for "cabal build; cabal run"
idx2 = t.find("cabal build; cabal run")
print("cabal build at", idx2)
if idx2!=-1:
    print(t[idx2-500:idx2+1000][:1500])
