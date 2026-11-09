from PIL import Image
from pathlib import Path
import json
ROOT = Path(__file__).resolve().parents[1]
manifest = json.loads((ROOT / 'manifest.json').read_text())
reports=[]
for pose in manifest['poses'][:3]:
    p=ROOT/pose['file']; im=Image.open(p); a=im.getchannel('A'); h=a.histogram()
    visible=a.point(lambda x:255 if x>=16 else 0).getbbox()
    assert im.mode=='RGBA' and im.size==(1254,1254)
    assert h[0] > im.width*im.height*.7
    assert visible[0]>16 and visible[1]>16 and visible[2]<1238 and visible[3]<1238
    s=manifest['shared_source_scale']; ax,ay=manifest['shared_source_anchor']
    bbox=[64+(visible[0]-ax)*s,124+(visible[1]-ay)*s,64+(visible[2]-ax)*s,124+(visible[3]-ay)*s]
    assert bbox[0]>=8 and bbox[1]>=3.9 and bbox[2]<=120 and bbox[3]<=124.2
    reports.append({'pose':pose['id'],'visible_bounds_in_128_canvas':bbox,'alpha_background':'pass','visible_margin':'pass','shared_pivot_contract':'pass'})
(ROOT/'qa'/'validation-report.json').write_text(json.dumps(reports,indent=2))
print(json.dumps(reports,indent=2))
