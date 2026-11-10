#!/usr/bin/env python3
"""Read-only validation of candidate source bytes and engine sizing metadata."""
import hashlib, json
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
specs=json.loads((ROOT/'specs.json').read_text())['storm_imp']
hashes={Path(r['file']).name:r['sha256'] for r in json.loads((ROOT/'source-hashes.json').read_text()) if r['role']=='storm_imp'}
checks=0
def check(ok,label):
 global checks
 checks+=1
 assert ok,label
report={}
for direction,key in [('sw','idle'),('se','idle-se'),('ne','idle-ne'),('nw','idle-nw')]:
 row=specs[key]; path=ROOT/row['file']; im=Image.open(path);a=im.getchannel('A');visible=a.point(lambda x:255 if x>=16 else 0).getbbox()
 check(im.mode=='RGBA',direction+' must retain RGBA');check(im.size==(1254,1254),direction+' source canvas');check(hashlib.sha256(path.read_bytes()).hexdigest()==hashes[path.name],direction+' source bytes');check(a.histogram()[0]>im.width*im.height*.65,direction+' real transparency');check(0<visible[0]<visible[2]<im.width and 0<visible[1]<visible[3]<im.height,direction+' visible alpha not clipped');check(0<row['scale']<1,direction+' valid scale');check(0<=row['pivot'][0]<im.width and 0<=row['pivot'][1]<im.height,direction+' valid pivot');height=(visible[3]-visible[1])*row['scale'];check(abs(height-88.610788238)<.1,direction+' height agrees with retained SW reference');check(0<(row['pivot'][1]-visible[3])*row['scale']<.5,direction+' visible foot baseline within half pixel of pivot')
 report[direction]={'visible_bounds_alpha16':visible,'body_height_px':height,'pivot':row['pivot'],'scale':row['scale'],'fully_transparent_fraction':a.histogram()[0]/(im.width*im.height)}
print(json.dumps(report,indent=2));print(f'Hollow source geometry: {checks} checks, 0 failures')
