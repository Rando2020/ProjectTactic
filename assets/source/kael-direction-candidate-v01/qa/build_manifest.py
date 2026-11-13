"""Write candidate metadata only; source pixels are never changed."""
from pathlib import Path
import hashlib,json
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
pivots={'se':([590,1248],42),'sw':([601,1223],38),'ne':([545,1200],32),'nw':([538,1229],31)}
m={'version':1,'character':'Kael swordsman candidate','production_ready':False,'candidate_accepted':False,'generator':'OpenAI built-in image_gen','date':'2026-11-09','reference_commit':'8d66158','reference_path':'demos/isometric-2v2/prototypes/isometric/assets/character-sets/painterly/originals/swordsman.png','target_body_height_px':86,'pivot_method':'Manual visual midpoint of projected boot soles. Head-to-foot-midpoint scaled to 86 px; not sword-dependent bounding box. Review calibration, not accepted production alignment.','directions':{}}
stats=[]
for d,(pivot,head) in pivots.items():
 p=ROOT/f'images/kael-idle-{d}-candidate.png'; im=Image.open(p); a=im.getchannel('A'); hist=a.histogram(); w,h=im.size
 bbox=a.point(lambda x:255 if x>=16 else 0).getbbox()
 m['directions'][d]={'file':str(p.relative_to(ROOT)),'canvas':[w,h],'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'foot_pivot_px':pivot,'head_top_px':head,'display_scale':86/(pivot[1]-head),'centered_sprite_offset_px':[w/2-pivot[0],h/2-pivot[1]],'flip_h':False,'equipment':{'sword_hand':'right','pauldron_shoulder':'left'},'status':'unapproved-generated-direction'}
 stats.append({'direction':d,'canvas':[w,h],'mode':im.mode,'alpha_zero_fraction':hist[0]/(w*h),'alpha_opaque_fraction':hist[255]/(w*h),'bounds_alpha_ge_16':bbox,'max_border_alpha':max(a.crop((0,0,w,1)).getextrema()[1],a.crop((0,h-1,w,h)).getextrema()[1],a.crop((0,0,1,h)).getextrema()[1],a.crop((w-1,0,w,h)).getextrema()[1])})
m['known_limits']=['No final character-art approval exists for this candidate.','Sparse alpha=1 specks at source boundaries are preserved. No masking, repainting, resampling, or mirroring was performed on sources.','Small embroidery placement, belt detail, scarf drape, and silhouette differences remain; NE coat emblem is not consistently on the same anatomical panel as front views.','Four discrete idle directions only, not walk/attack/cast/hurt/KO animation.','Generated front views are relatively frontal and require courtyard camera/readability acceptance.','No production mapping, gameplay scripts, saves, combat, deployment, or existing PNG was changed.']
(ROOT/'manifest.json').write_text(json.dumps(m,indent=2)+'\n')
(ROOT/'qa/alpha-report.json').write_text(json.dumps(stats,indent=2)+'\n')
