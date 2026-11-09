"""Read-only checks; never modifies generated art."""
import hashlib, json, math
from pathlib import Path
from PIL import Image
ROOT = Path(__file__).resolve().parents[1]
assert (ROOT/'manifest.json').exists(), 'candidate pivot manifest missing'
m=json.loads((ROOT/'manifest.json').read_text())
assert m['production_ready'] is False
assert list(m['directions']) == ['se','sw','ne','nw']
checks=2
for direction,v in m['directions'].items():
 p=ROOT/v['file']; im=Image.open(p)
 assert im.mode=='RGBA'; checks+=1
 assert list(im.size)==v['canvas']; checks+=1
 assert hashlib.sha256(p.read_bytes()).hexdigest()==v['sha256']; checks+=1
 alpha=im.getchannel('A'); hist=alpha.histogram()
 assert hist[0]/(im.width*im.height)>.65; checks+=1
 assert max(alpha.crop((0,0,im.width,1)).getextrema())<=1; checks+=1
 assert v['flip_h'] is False; checks+=1
 assert v['equipment']['sword_hand']=='right'; checks+=1
 assert v['equipment']['pauldron_shoulder']=='left'; checks+=1
 x,y=v['foot_pivot_px']; assert 0<x<im.width and 0<y<im.height; checks+=1
 scale=v['display_scale']; assert math.isfinite(scale) and 0<scale<1; checks+=1
 top=v['head_top_px']; assert abs((y-top)*scale-86)<1e-6; checks+=1
 assert all(abs(v['centered_sprite_offset_px'][i]-(im.size[i]/2-v['foot_pivot_px'][i]))<1e-7 for i in [0,1]); checks+=1
print(f'{checks} asset contract checks passed')
