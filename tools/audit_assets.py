"""Conservative tracked-asset inventory. Reference absence is NOT deletion approval."""
import csv, hashlib, subprocess
from collections import Counter, defaultdict
from pathlib import Path
root = Path(__file__).resolve().parents[1]
files = subprocess.check_output(['git','ls-files'], cwd=root, text=True).splitlines()
exts = {'.png','.jpg','.jpeg','.webp','.svg','.wav','.ogg','.mp3','.ttf','.glb','.gltf','.obj','.blend'}
assets = [p for p in files if Path(p).suffix.lower() in exts]
sources = [(p,(root/p).read_text(errors='ignore')) for p in files if Path(p).suffix in {'.gd','.tscn','.tres','.json','.jsx','.js','.css','.html'} and not p.startswith('docs/')]
hashes = defaultdict(list)
for p in assets: hashes[hashlib.sha256((root/p).read_bytes()).hexdigest()].append(p)
rows=[]
for p in assets:
    refs=[name for name,text in sources if p in text or (p.startswith('godot/') and 'res://'+p[6:] in text)]
    if p.startswith('preview/') or p in ['_ante.png','_roster.png']: status='reference only; not runtime'
    elif p.startswith(('src/','ui_kits/')): status='legacy web/source kit; preserve outside Godot'
    elif refs: status='referenced; retain (may be fallback)'
    else: status='unresolved/dynamic reference; review before removal'
    digest=hashlib.sha256((root/p).read_bytes()).hexdigest()
    rows.append([p,status,(root/p).stat().st_size,digest,';'.join(x for x in hashes[digest] if x!=p),';'.join(refs)])
out=root/'docs/production/asset-audit.csv'
with out.open('w') as f:
    w=csv.writer(f);w.writerow(['path','disposition','bytes','sha256','identical_files','literal_reference_files']);w.writerows(rows)
print('Tracked assets:',len(rows));print(dict(Counter(r[1] for r in rows)));print('Exact duplicate groups:',sum(len(v)>1 for v in hashes.values()))
