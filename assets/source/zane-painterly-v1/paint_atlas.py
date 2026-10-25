#!/usr/bin/env python3
"""Original, deterministic painted color atlas; no generated/reference pixels copied.

Eight material fields. Broad value patches establish form; long tapered pigment
marks follow fabric/hair/forging grain. Deliberately no stochastic noise filter.
Coordinates are authored, normalized to each material tile. Run with Python/Pillow.
"""
from pathlib import Path
from PIL import Image, ImageDraw
OUT=Path(__file__).resolve().parent/'textures'
OUT.mkdir(exist_ok=True)
# Palette in display/sRGB. Vertex-color light planes add authored local variation.
PALETTE=[('navy',(45,59,82)),('cream',(219,202,165)),('steel',(79,86,94)),('leather',(83,53,34)),('skin',(193,132,91)),('hair',(74,43,27)),('brass',(166,125,66)),('dark',(44,41,37))]
img=Image.new('RGB',(1024,1024)); d=ImageDraw.Draw(img)
patches=[([(.05,.10),(.48,.02),(.68,.30),(.36,.52),(.08,.37)],1.05),([(.50,.0),(.98,.0),(.99,.55),(.78,.42)],.94),([(.0,.46),(.29,.37),(.47,.71),(.17,.99),(.0,.93)],.92),([(.33,.59),(.62,.39),(.86,.77),(.66,1),(.48,1)],1.035),([(.85,.47),(1,.55),(1,1),(.73,1)],.965)]
strokes=[(.13,.13,.030,.20),(.24,.51,.023,.25),(.42,.20,.018,.28),(.56,.67,.025,.20),(.72,.12,.023,.19),(.83,.53,.017,.27),(.35,.75,.018,.17),(.92,.22,.020,.15),(.62,.35,.018,.14),(.06,.72,.017,.19),(.49,.47,.012,.11),(.76,.84,.019,.12)]
for idx,(name,base) in enumerate(PALETTE):
 x0=(idx%4)*256; y0=(idx//4)*512
 d.rectangle((x0,y0,x0+255,y0+511),fill=base)
 def color(f):return tuple(max(0,min(255,round(c*f))) for c in base)
 def points(p):return [(x0+int(12+x*232),y0+int(12+y*488)) for x,y in p]
 for p,f in patches:d.polygon(points(p),fill=color(f))
 # Keep skin quiet; brush accents on armor/fabric have material-specific direction.
 contrast=.035 if name=='skin' else .085 if name in ('hair','leather') else .055
 for j,(x,y,w,h) in enumerate(strokes):
  slant=.08 if name in ('steel','brass') else -.025 if name=='hair' else .025
  d.polygon(points([(x,y),(x+w,y+.012),(x+slant+w*.22,y+h),(x+slant,y+h*.91)]),fill=color(1+contrast if j%3 else 1-contrast))
 # Broad brushed edge glint, not a repeating fine noise field.
 if name in ('steel','brass'):
  for x,y,w,h in [(.19,.04,.015,.36),(.68,.51,.012,.30),(.88,.07,.011,.23)]:d.polygon(points([(x,y),(x+w,y),(x+.06,y+h),(x+.052,y+h*.96)]),fill=color(1.12))
img.save(OUT/'zane_painterly_atlas.png',optimize=True)
print(OUT/'zane_painterly_atlas.png')
