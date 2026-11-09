from pathlib import Path
import json, hashlib
from PIL import Image
import numpy as np
ROOT=Path(__file__).parent
DATA={
'se':((192,103,1017,1167),(666,1118),'approved-reference','d299d45c28f164620beee1d88871edea780ce4ad3c4873f1bea86735b64ab236'),
'sw':((252,118,975,1141),(599,1066),'unapproved-facing','cb19662628e53dc09075739cd021205453795e9c117d8fb531f0be9320a7e457'),
'ne':((317,99,974,1113),(553,1081),'unapproved-facing','07f9d08356739d5ac3a0084f216e8c988abf5889d295da8127fb1e0ce94c63b8'),
'nw':((450,184,979,1025),(641,986),'unapproved-facing','34611d7e1190ab06df24cd229bd7850e10651cf3dabb286163bec5ef899d73db'),
'cast-lift-se':(None,(666,1118),'unapproved-cast-inbetween',None),
'cast-extend-se':(None,(666,1118),'unapproved-cast-inbetween',None),
'cast-windup-se':(None,(666,1118),'unapproved-cast-keypose',None),
'cast-release-se':(None,(666,1118),'unapproved-cast-keypose',None),
}
files={}
for name,(expected,pivot,status,known_hash) in DATA.items():
 p=ROOT/'images'/f'{name}.png'; im=Image.open(p); a=np.array(im.getchannel('A'))
 ys,xs=np.nonzero(a>=128); b=[int(xs.min()),int(ys.min()),int(xs.max()+1),int(ys.max()+1)]
 sha=hashlib.sha256(p.read_bytes()).hexdigest()
 assert im.mode=='RGBA' and im.size==(1254,1254)
 assert known_hash is None or known_hash==sha
 assert expected is None or list(expected)==b
 assert b[0]>0 and b[1]>0 and b[2]<1254 and b[3]<1254
 border=np.concatenate([a[0,:],a[-1,:],a[1:-1,0],a[1:-1,-1]])
 files[name]={'file':f'images/{name}.png','sha256':sha,'size':[1254,1254],'bounds_alpha_ge_128':b,'pivot':list(pivot),'scale':85/(1064 if name.startswith('cast') else b[3]-b[1]),'status':status,'alpha_zero_fraction':float(np.mean(a==0)),'max_border_alpha':int(border.max()),'flip_h':False}
# Pure read-only lower-boot alpha alignment measurement. Does not alter source PNGs.
idle=np.array(Image.open(ROOT/'images/se.png').getchannel('A')).astype(float)
for name in ['cast-lift-se','cast-windup-se','cast-extend-se','cast-release-se']:
 a=np.array(Image.open(ROOT/f'images/{name}.png').getchannel('A')).astype(float)
 best=None
 for dy in range(-10,11):
  for dx in range(-10,11):
   err=np.mean(np.abs(idle[950:1180,450:850]-a[950+dy:1180+dy,450+dx:850+dx]))
   if best is None or err<best[0]: best=(err,dx,dy)
 files[name]['boot_region_best_alpha_shift_px']=[best[1],best[2]]
 files[name]['boot_region_mean_alpha_difference']=round(best[0],3)
manifest={'version':1,'production_ready':False,'candidate_accepted':False,'target_idle_height_px':85,'pivot_method':'Manual midpoint between visible boot sole contacts; review calibration only, not production accepted. SE cast uses identical transform to SE idle.','timing_seconds':{'lift':0.08,'windup':0.12,'extend':0.08,'release':0.24,'recovery_extend':0.08,'recovery_windup':0.08,'recovery_lift':0.08},'files':files}
(ROOT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print('PASS: eight genuine RGBA sources, four recovered hashes, unclipped visible bounds; source pixels untouched.')
for name in ['cast-lift-se','cast-windup-se','cast-extend-se','cast-release-se']: print(name,files[name]['bounds_alpha_ge_128'],files[name]['boot_region_best_alpha_shift_px'])
