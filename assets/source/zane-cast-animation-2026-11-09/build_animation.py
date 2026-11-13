"""Assemble unchanged generated PNGs into timed animation exports using FFmpeg."""
from pathlib import Path
import subprocess, json
ROOT=Path(__file__).resolve().parent
OUT=ROOT/'animation'; FRAMES=OUT/'frame-sequence'
OUT.mkdir(exist_ok=True);FRAMES.mkdir(exist_ok=True)
# 20 ms ticks ensure exact declared timings. Playback includes idle holds.
SEQUENCE=[('se',600),('cast-lift-se',80),('cast-windup-se',120),('cast-extend-se',80),('cast-release-se',240),('cast-extend-se',80),('cast-windup-se',80),('cast-lift-se',80),('se',640)]
assert sum(t for _,t in SEQUENCE)==2000
names=[]
for name,ms in SEQUENCE:
 names += [name]*(ms//20)
for i,name in enumerate(names):
 f=FRAMES/f'frame-{i:03}.png'
 if f.exists() or f.is_symlink(): f.unlink()
 f.symlink_to(ROOT/'images'/f'{name}.png')
(OUT/'timeline.json').write_text(json.dumps({'fps':50,'loop_ms':2000,'cast_ms':760,'release_event_cast_ms':280,'release_event_clip_ms':880,'unique_art_poses':5,'interpolation':'none','source_pixels':'unchanged RGBA, no warping or image blending','segments':[{'pose':n,'duration_ms':ms} for n,ms in SEQUENCE],'frame_sources':names},indent=2)+'\n')
def run(args):
 subprocess.run(['ffmpeg','-hide_banner','-loglevel','warning','-y',*args],check=True)
run(['-framerate','50','-i',str(FRAMES/'frame-%03d.png'),'-frames:v','100','-c:v','apng','-pix_fmt','rgba','-plays','0',str(OUT/'Zane-SE-Cast-Transparent.apng')])
font='/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
filters=f"""[0:v]split=2[a][b];[a]scale=590:590:flags=lanczos[large];[b]scale=100:100:flags=lanczos[small];color=c=0x12212b:s=1280x720:r=50:d=2[bg];[bg][large]overlay=100:77:shortest=1[x];[x][small]overlay=933:477:shortest=1[y];[y]drawtext=fontfile={font}:text='ZANE / SOUTHEAST CAST':x=60:y=24:fontsize=28:fontcolor=0xeadac0,drawtext=fontfile={font}:text='5 authored poses  /  760 ms cast':x=760:y=155:fontsize=22:fontcolor=0xeadac0,drawtext=fontfile={font}:text='Lift > windup > extend > release':x=760:y=200:fontsize=18:fontcolor=0xa9c0cb,drawtext=fontfile={font}:text='Recovery follows the same poses back.':x=760:y=230:fontsize=18:fontcolor=0xa9c0cb,drawtext=fontfile={font}:text='Release event at 280 ms':x=760:y=285:fontsize=18:fontcolor=0xd9ba7f,drawtext=fontfile={font}:text='85 px gameplay-size reference':x=817:y=603:fontsize=17:fontcolor=0xd9ba7f,drawtext=fontfile={font}:text='CANDIDATE ANIMATION EXPORT  /  NOT AN ENGINE CAPTURE':x=60:y=680:fontsize=18:fontcolor=0xa9c0cb,format=yuv420p[out]"""
run(['-framerate','50','-i',str(FRAMES/'frame-%03d.png'),'-filter_complex',filters,'-map','[out]','-frames:v','100','-c:v','libx264','-preset','medium','-crf','17','-movflags','+faststart',str(OUT/'review-once.mp4')])
run(['-stream_loop','2','-i',str(OUT/'review-once.mp4'),'-c','copy','-movflags','+faststart',str(OUT/'Zane-SE-Cast-Preview.mp4')])
print('Created transparent two-second APNG loop and six-second MP4 review; no generated-image pixels modified.')
