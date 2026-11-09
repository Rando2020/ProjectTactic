"""Deterministic core extraction. No generated pixels or alpha thresholding."""
from pathlib import Path
import hashlib,json
import numpy as np
from PIL import Image,ImageDraw
from scipy.ndimage import label
ROOT=Path(__file__).resolve().parent
(ROOT/'qa').mkdir(exist_ok=True)
(ROOT/'frames').mkdir(exist_ok=True)
SRC=ROOT/'originals/fireball-original.png'
SHA='454653e135c94ae0e9f481674b5ad82bdeb7270787cb46f55d6446089aa74fa3'
assert hashlib.sha256(SRC.read_bytes()).hexdigest()==SHA
im=Image.open(SRC).convert('RGBA'); arr=np.array(im)
labels,count=label(arr[:,:,3]>0) # default 4-connected; preserve every nonzero alpha in selected component
sizes=np.bincount(labels.ravel()); sizes[0]=0
# Source interior seed coordinates, selected by visual inspection of each core.
seeds=[(185,215),(540,213),(900,213),(1260,213),(248,389),(645,358),(1005,358),(1374,356),(185,686),(542,690),(900,720),(1260,690),(190,990),(545,990),(900,990),(1290,910)]
# Interior seeds deliberately identify each isolated coherent effect; detached droplets are omitted.
stages=['charge']*4+['travel']*4+['impact']*4+['dissipate']*4
anchors=[(185,215),(540,213),(900,213),(1260,213),(248,389),(645,358),(1005,358),(1374,356),(185,740),(542,760),(900,770),(1260,780),(190,1040),(545,1040),(900,1040),(1260,1040)]
entries=[]; selected=[]
for i,(seed,stage,anchor) in enumerate(zip(seeds,stages,anchors),1):
 x,y=seed; cid=int(labels[y,x]); assert cid and sizes[cid]>8000
 # Visually selected interior seed identifies a core; not rectangular atlas stepping.
 assert cid not in selected; selected.append(cid)
 ys,xs=np.where(labels==cid); box=(int(xs.min()),int(ys.min()),int(xs.max()+1),int(ys.max()+1))
 crop=arr[box[1]:box[3],box[0]:box[2]].copy(); mask=labels[box[1]:box[3],box[0]:box[2]]==cid
 crop[~mask]=0
 pivot=(320,256) if stage=='travel' else (256,400)
 dest=(pivot[0]-(anchor[0]-box[0]),pivot[1]-(anchor[1]-box[1]))
 assert dest[0]>=0 and dest[1]>=0 and dest[0]+crop.shape[1]<=512 and dest[1]+crop.shape[0]<=512
 out=np.zeros((512,512,4),dtype=np.uint8); out[dest[1]:dest[1]+crop.shape[0],dest[0]:dest[0]+crop.shape[1]]=crop
 filename=f'{i:02d}_{stage}.png'; Image.fromarray(out).save(ROOT/'frames'/filename)
 entries.append(dict(index=i,stage=stage,file='frames/'+filename,source_component=cid,visible_pixels=int(sizes[cid]),source_bbox=list(box),source_anchor=list(anchor),canvas_pivot=list(pivot),paste_position=list(dest),duration_ms=[90,90,90,90,70,70,70,70,65,65,80,100,100,110,120,150][i-1],sha256=hashlib.sha256((ROOT/'frames'/filename).read_bytes()).hexdigest()))
manifest=dict(source_library_id='libfile_0953684bc2008191b9448fe9ca08a1d5',source_sha256=SHA,source_size=list(im.size),canvas_size=[512,512],extraction='One visually seeded 4-connected nonzero-alpha core component per stage. Original source RGBA values unchanged for selected pixels. Detached sparks and halos excluded.',timing_status='Proposed preview timing only, not gameplay timing or final animation acceptance.',travel_direction='Artwork points upper-right. Not four bespoke directional animations.',frames=entries)
(ROOT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
# Exact-source reconstruction tests per exported frame.
for e in entries:
 out=np.array(Image.open(ROOT/e['file'])); assert out.shape==(512,512,4)
 x0,y0,x1,y1=e['source_bbox']; dx,dy=e['paste_position']; mask=labels[y0:y1,x0:x1]==e['source_component']
 patch=out[dy:dy+y1-y0,dx:dx+x1-x0]
 assert np.array_equal(patch[mask],arr[y0:y1,x0:x1][mask])
 assert np.count_nonzero(out[:,:,3])==e['visible_pixels']
 assert np.count_nonzero(patch[~mask])==0
 assert not(out[0,:,3].any() or out[-1,:,3].any() or out[:,0,3].any() or out[:,-1,3].any())
# QA contact sheet: dark flat background, preview only (not effect asset).
preview=Image.new('RGB',(1024,1152),(27,32,43)); d=ImageDraw.Draw(preview)
for e in entries:
 i=e['index']-1;x=i%4*256;y=i//4*288
 frame=Image.open(ROOT/e['file']).resize((256,256),Image.Resampling.LANCZOS)
 preview.paste(frame,(x,y),frame);d.text((x+10,y+260),f"{i+1:02d} {e['stage']}",fill=(240,240,240))
preview.save(ROOT/'qa/contact-sheet.png')
report=dict(result='PASS',checks=['source SHA-256 exact','16 distinct components','16 RGBA canvases','all selected source pixel values exact','no pixels from other components','no alpha-edge clipping','consistent per-stage pivots','per-frame hashes recorded'],selected_pixels=sum(e['visible_pixels'] for e in entries),source_nonzero_alpha_pixels=int(np.count_nonzero(arr[:,:,3])),omitted_pixels=int(np.count_nonzero(arr[:,:,3]))-sum(e['visible_pixels'] for e in entries))
(ROOT/'qa/validation.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report))
