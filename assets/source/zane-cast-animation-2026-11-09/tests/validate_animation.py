from pathlib import Path
from PIL import Image
import numpy as np,json,subprocess
R=Path(__file__).resolve().parents[1]
timeline=json.loads((R/'animation/timeline.json').read_text())
im=Image.open(R/'animation/Zane-SE-Cast-Transparent.apng')
assert im.size==(1254,1254) and im.n_frames==100
source={name:np.array(Image.open(R/f'images/{name}.png').convert('RGBA')) for name in set(timeline['frame_sources'])}
duration=0
for i,name in enumerate(timeline['frame_sources']):
 im.seek(i); frame=np.array(im.convert('RGBA'));duration+=im.info['duration']
 assert np.array_equal(frame,source[name]),f'Frame {i} differs from raw {name}'
assert abs(duration-2000)<0.001
probe=json.loads(subprocess.check_output(['ffprobe','-v','error','-count_frames','-show_entries','stream=width,height,nb_read_frames,r_frame_rate:format=duration','-of','json',str(R/'animation/Zane-SE-Cast-Preview.mp4')]))
s=probe['streams'][0]
assert s['width']==1280 and s['height']==720 and s['nb_read_frames']=='300'
assert abs(float(probe['format']['duration'])-6)<0.001
result={'apng_frames':100,'apng_duration_ms':duration,'apng_size':[1254,1254],'apng_rgba_pixel_equality_to_sources':'100/100 exact','source_images':5,'mp4_frames':300,'mp4_duration_s':6,'mp4_resolution':[1280,720],'release_event_ms_from_cast_start':280,'engine_capture':False,'visual_acceptance':False}
(R/'evidence/animation-validation.json').write_text(json.dumps(result,indent=2)+'\n')
print('PASS: 100/100 APNG frames exactly equal original RGBA pixels; 2000ms loop. MP4: 300 frames / 6s / 1280x720. No engine-render claim.')
