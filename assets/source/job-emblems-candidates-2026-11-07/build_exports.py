#!/usr/bin/env python3
"""Reproducible mechanical PNG export and QA; never regenerates or repaints art."""
from pathlib import Path
import json, hashlib, shutil, subprocess
from PIL import Image
import numpy as np

ROOT = Path(__file__).resolve().parent
JOBS = ['squire', 'arcanist', 'scout', 'warder', 'luminary', 'shadow']
LEGACY = ['knight', 'mage', 'archer', 'guardian', 'cleric', 'rogue']
SIZES = [128,64,48,32]

def cmd(*args):
    subprocess.run(['magick', *map(str,args)], check=True)

def measure(path):
    im = Image.open(path)
    a = np.array(im.convert('RGBA'))[:,:,3]
    ys, xs = np.where(a >= 8)
    bounds = [int(xs.min()),int(ys.min()),int(xs.max()+1),int(ys.max()+1)]
    return {'file':str(path.relative_to(ROOT)), 'size_bytes':path.stat().st_size,
        'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),
        'dimensions':list(im.size), 'mode':im.mode, 'alpha_bounds_ge8':bounds,
        'transparent_fraction':round(float((a == 0).mean()),6),
        'opaque_fraction':round(float((a == 255).mean()),6),
        'alpha_extrema':[int(a.min()),int(a.max())],
        'edge_alpha_max':int(max(a[0].max(),a[-1].max(),a[:,0].max(),a[:,-1].max()))}

def build():
    for d in ['originals','exports','review']:
        (ROOT/d).mkdir(exist_ok=True)
    records=json.loads((ROOT/'prompts.json').read_text())
    assets=[]
    for rec, legacy in zip(records,LEGACY):
        job=rec['id']
        original=ROOT/'originals'/f'job-{job}-master-v01.png'
        if not original.exists():
            shutil.copy2(rec['source'],original)
        files=[measure(original)]
        x0,y0,x1,y1=files[0]['alpha_bounds_ge8']
        crop=f'{x1-x0}x{y1-y0}+{x0}+{y0}'
        for size in SIZES:
            inner=round(size*.80)
            dest=ROOT/'exports'/f'job-{job}-{size}-v01.png'
            cmd(original,'-crop',crop,'+repage','-filter','Lanczos','-resize',f'{inner}x{inner}',
                '-gravity','center','-background','none','-extent',f'{size}x{size}',
                '-define','png:color-type=6',dest)
            stats=measure(dest)
            assert stats['dimensions']==[size,size]
            assert stats['mode']=='RGBA'
            assert stats['alpha_extrema']==[0,255]
            assert stats['edge_alpha_max']==0
            files.append(stats)
        assets.append({'job_id':job, 'existing_icon_path':f'godot/assets/generated/icons/job-{legacy}-icon.png',
            'status':'normalized_candidate', 'art_approval':'pending','runtime_status':'not_imported',
            'role_source':'godot/scripts/data/JobTreeData.gd', 'files':files})
    manifest={'schema':'projecttactic-job-emblems-v1','date':'2026-11-07',
        'repository':'Rando2020/ProjectTactic', 'verified_base':'c763f976b04c361ad687721a6e61e27c3b0826a1',
        'generator':'built-in image_gen.imagegen',
        'processing':'Original RGBA retained; crop to alpha >=8 visible bounds, Lanczos downscale, center on transparent canvas. Only negligible outer alpha speckles outside those bounds are excluded; no repainting, background masking, or gameplay change.',
        'alpha_checks':'All exports have transparent edges and both alpha 0 and 255.',
        'ui_contract':'Render live job labels/tooltips; use at >=32px; scalable frames/state/focus remain engine-owned.',
        'assets':assets}
    (ROOT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    # Contact sheet is QA, not an atlas and never intended for runtime import.
    base=ROOT/'review'/'job-emblems-overview.png'
    args=['-size','1320x860','canvas:#202535','-font','DejaVu-Sans','-fill','#F0E8D8',
        '-pointsize','30','-annotate','+36+49','ProjectTactic | Six job emblems',
        '-pointsize','16','-fill','#B7BBC5','-annotate','+36+80','Painterly RGBA candidates | Existing job IDs | No runtime integration']
    for i,job in enumerate(JOBS):
        x=40+i*213
        original=ROOT/'originals'/f'job-{job}-master-v01.png'
        args += ['(',str(original),'-trim','+repage','-resize','160x190',')','-gravity','NorthWest','-geometry',f'+{x+20}+125','-composite']
        args += ['-fill','#F0E8D8','-pointsize','20','-annotate',f'+{x+22}+349',job.title()]
    y=390
    for size in [64,48,32]:
        args += ['-fill','#B7BBC5','-pointsize','16','-annotate',f'+36+{y-12}',f'{size}px native scale on ink']
        for i,job in enumerate(JOBS):
            args += ['(',str(ROOT/'exports'/f'job-{job}-{size}-v01.png'),')','-geometry',f'+{40+i*213+65}+{y}','-composite']
        y += size+45
    args += ['-fill','#D8C6A4','-draw','rectangle 24,687 1296,808','-fill','#202535','-pointsize','16','-annotate','+36+714','32px native scale on cream / grayscale']
    for i,job in enumerate(JOBS):
        p=ROOT/'exports'/f'job-{job}-32-v01.png'
        args += ['(',str(p),')','-geometry',f'+{40+i*213+44}+740','-composite',
            '(',str(p),'-colorspace','Gray',')','-geometry',f'+{40+i*213+95}+740','-composite']
    args += ['-fill','#B7BBC5','-pointsize','14','-annotate','+36+839','Individual masters and 128 / 64 / 48 / 32 px exports included. These are icons, not character sprites or new mechanics.',str(base)]
    cmd(*args)
    print(json.dumps({'generated_masters':len(assets),'rgba_exports':len(assets)*len(SIZES),'checks':'pass','preview':str(base)},indent=2))

if __name__=='__main__':
    build()
