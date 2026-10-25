#!/usr/bin/env python3
"""Assemble labeled technical review sheets from actual Blender output; no paint-over."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
import argparse,json,hashlib,shutil
HERE=Path(__file__).resolve().parent
p=argparse.ArgumentParser();p.add_argument('--renders',type=Path,default=HERE/'renders-v4');p.add_argument('--output',type=Path,default=HERE/'review');p.add_argument('--turntable',type=Path);p.add_argument('--turntable-manifest',type=Path);a=p.parse_args();a.output.mkdir(exist_ok=True)
meta=json.loads((a.renders/'render_manifest.json').read_text());assert meta['sha256']=='14c7497613c45f58edd949c7c258a1b220e3d29d95e118ba2557dea98b411e20','Wrong reviewed V4 model'
sha=lambda path:hashlib.sha256(path.read_bytes()).hexdigest()
font=lambda size,bold=False:ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans'+('-Bold' if bold else '')+'.ttf',size)
bg=(22,30,35);fg=(233,225,207);sub=(165,180,185)
def header(image,title,subtitle):
 d=ImageDraw.Draw(image);d.text((28,24),title,font=font(34,True),fill=fg);d.text((30,72),subtitle,font=font(20),fill=sub);return d
img=Image.new('RGB',(1800,752),bg);d=header(img,'ZANE  /  V4  —  ACTUAL OFFLINE 3D','Real exported mesh · neutral studio lighting · not an in-game capture')
for i,(f,label) in enumerate([('02_front','FRONT'),('01_three_quarter','THREE-QUARTER'),('03_rear','REAR')]):
 im=Image.open(a.renders/(f+'.png')).convert('RGB').resize((570,570),Image.Resampling.LANCZOS);x=30+i*590;img.paste(im,(x,112));d.text((x,704),label,font=font(22,True),fill=fg)
img.save(a.output/'neutral-turnaround.png',optimize=True)
poses=[('06_walk_stride','WALK · stride'),('07_walk_contact','WALK · contact'),('08_slash_load','SLASH · load'),('09_slash_contact','SLASH · contact'),('10_slash_follow','SLASH · follow-through'),('11_cast_load','CAST · load'),('12_cast_release','CAST · release'),('13_cast_recoil','CAST · recoil'),('14_defeat_kneel','DEFEAT · floor clearance')]
img=Image.new('RGB',(1260,1376),bg);d=header(img,'V4  /  UNCHANGED MOTION','Actual exported-GLB poses · fixed gameplay camera projection · offline renders')
for i,(f,label) in enumerate(poses):
 x=24+(i%3)*412;y=110+(i//3)*414
 im=Image.open(a.renders/(f+'.png')).convert('RGB').resize((396,396),Image.Resampling.LANCZOS);img.paste(im,(x,y));d.text((x,y+373),label,font=font(17,True),fill=(15,23,27),stroke_width=2,stroke_fill=(195,205,207))
d.text((24,1352),'Ortho 3.2 · pitch 30° · yaw 45° · nine original impact clips preserved',font=font(16),fill=sub);img.save(a.output/'game-camera-motion.png',optimize=True)
shutil.copyfile(a.renders/'04_face_detail.png',a.output/'face-detail.png')
Image.open(a.renders/'05_game_ortho_idle.png').convert('RGB').resize((138,138),Image.Resampling.LANCZOS).save(a.output/'game-scale-138.png')
if a.turntable:
 assert a.turntable_manifest,'Turntable requires its exact model manifest'
 tm=json.loads(a.turntable_manifest.read_text());assert tm['sha256']==meta['sha256'];assert len(tm['views'])==48;assert all(v.get('conservative_model_projected_bounds') for v in tm['views']);shutil.copyfile(a.turntable,a.output/'turntable.mp4')
else:tm=None
outputs=[p for p in a.output.iterdir() if p.suffix in ('.png','.mp4')]
report={'revision':'V4 blade-framing refinement','model_sha256':meta['sha256'],'evidence_type':'ACTUAL OFFLINE 3D RENDERS OF THE EXPORTED GLB','not_in_game_capture':True,'not_generated_illustration':True,'no_paint_over':True,'source_render_samples':meta['samples'],'lighting':meta['lighting'],'source_render_manifest':meta,'turntable_render_manifest':tm,'turntable_video':{'frames':48,'fps':12,'seconds':4,'encoding':'H264, yuv420p, CRF18'} if tm else None,'game_scale_proxy':{'image_width_px':138,'intended_runtime_display_size_local_canvas_px':138.24,'note':'Rounded one-to-one pixel proxy; conversation UI may scale the displayed image.'},'files':{p.name:{'sha256':sha(p),'bytes':p.stat().st_size} for p in outputs},'source_image_sha256':{p.name:sha(p) for p in a.renders.glob('*.png')}}
(a.output/'manifest.json').write_text(json.dumps(report,indent=2)+'\n');print(a.output)
