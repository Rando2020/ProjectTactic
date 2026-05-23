from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter
import random, math
ROOT=Path(__file__).resolve().parents[1]
A=ROOT/'godot'/'assets'
random.seed(19)
def S(img,p):
 p.parent.mkdir(parents=True,exist_ok=True)
 try:
  img.save(p); print(p.relative_to(ROOT))
 except PermissionError:
  print('SKIP locked', p.relative_to(ROOT))
def adj(c,n): return tuple(max(0,min(255,int(c[i]+n))) for i in range(3))+(c[3] if len(c)>3 else 255,)
def dia(w=96,h=64,p=4): return [(w//2,p),(w-p,h//2),(w//2,h-p),(p,h//2)]
def in_d(x,y,w=96,h=64): return abs(x-w/2)/(w/2-7)+abs(y-h/2)/(h/2-7)<=1
def tile(base,accent,kind,seed):
 r=random.Random(seed); im=Image.new('RGBA',(96,64),(0,0,0,0)); d=ImageDraw.Draw(im,'RGBA'); q=dia(); d.polygon(q,fill=base,outline=adj(base,-50))
 for _ in range(88):
  x=r.randint(9,86); y=r.randint(8,55)
  if not in_d(x,y): continue
  col=accent if r.random()<.23 else adj(base,r.randint(-24,31))
  if kind in ['water','ice']: d.line((x-7,y,x+7,y+r.choice([-1,0,1])),fill=col[:3]+(105,),width=1)
  elif kind in ['stone','road','crack']: d.line((x-4,y,x+r.randint(3,8),y+r.randint(-2,2)),fill=col[:3]+(100,),width=1)
  else: d.line((x,y,x+r.randint(-4,4),y+r.randint(-2,2)),fill=col[:3]+(120,),width=1)
 if kind=='flowers':
  for _ in range(18):
   x=r.randint(18,78); y=r.randint(14,48)
   if in_d(x,y): d.ellipse((x-1,y-1,x+1,y+1),fill=(249,220,116,225))
 if kind=='brush':
  for _ in range(14):
   x=r.randint(17,79); y=r.randint(14,49); d.arc((x-6,y-5,x+6,y+5),195,345,fill=(29,74,38,190),width=2)
 if kind=='road':
  for y in [22,31,40]: d.line((18,y,78,y+r.randint(-2,2)),fill=(82,59,39,135),width=2)
 if kind=='water':
  for y in [19,28,37,46]: d.arc((14,y-6,82,y+8),8,172,fill=(151,229,247,125),width=2)
 if kind=='ice':
  for _ in range(8):
   x=r.randint(20,76); y=r.randint(16,45); d.line((x-6,y+2,x,y-4,x+7,y+1),fill=(237,252,255,170),width=1)
 if kind=='burn':
  for _ in range(14):
   x=r.randint(20,76); y=r.randint(16,47); d.polygon([(x,y-6),(x+4,y+2),(x,y+6),(x-4,y+1)],fill=(255,120+r.randint(0,80),36,160))
 if kind=='crack':
  for _ in range(6):
   x=r.randint(21,68); y=r.randint(17,45); d.line([(x,y),(x+r.randint(4,10),y+r.randint(-3,3)),(x+r.randint(10,18),y+r.randint(1,7))],fill=(20,22,25,165),width=2)
 if kind=='shrine':
  d.ellipse((37,18,59,40),fill=(247,218,111,135),outline=(255,246,180,200),width=2); d.polygon([(48,13),(56,30),(48,48),(40,30)],outline=(255,246,180,230),fill=(122,86,45,80))
 if kind=='void': d.ellipse((29,15,67,49),fill=(96,36,145,155),outline=(210,84,255,190),width=3); d.line((48,12,48,52),fill=(230,120,255,180),width=2)
 if kind=='elite': d.polygon([(48,13),(61,30),(48,50),(35,30)],fill=(199,45,38,140),outline=(255,195,80,200))
 if kind=='boss': d.ellipse((22,8,74,56),outline=(255,72,86,220),width=3); d.line((30,43,66,20),fill=(255,72,86,175),width=2)
 d.line(q+[q[0]],fill=(255,255,255,55),width=1); return im.filter(ImageFilter.UnsharpMask(radius=1,percent=80,threshold=2))
T={
'grass.png':((48,120,55,255),(101,164,75,255),'grass'),'grass_flowers.png':((54,125,58,255),(245,220,120,255),'flowers'),'brush.png':((45,95,48,255),(24,68,36,255),'brush'),'road.png':((128,93,55,255),(171,131,75,255),'road'),'stone.png':((93,99,105,255),(134,139,142,255),'stone'),'cracked_stone.png':((75,78,83,255),(121,124,128,255),'crack'),'shallow_water.png':((42,132,163,230),(138,224,244,255),'water'),'frozen_water.png':((150,210,226,245),(235,251,255,255),'ice'),'burning_grass.png':((112,51,27,255),(255,101,35,255),'burn'),'scorched_dirt.png':((47,38,32,255),(92,67,49,255),'crack'),'cliff_grass.png':((72,102,72,255),(129,143,101,255),'stone'),'holy_shrine.png':((117,91,50,255),(246,218,109,255),'shrine'),'wall-tile-placeholder.png':((40,43,51,255),(93,96,105,255),'stone'),'void-corruption-tile.png':((45,20,68,255),(208,82,255,255),'void'),'elite-spawn-tile.png':((96,42,38,255),(255,196,80,255),'elite'),'boss-arena-tile.png':((61,31,45,255),(255,72,86,255),'boss')}
for i,(n,v) in enumerate(T.items()): S(tile(*v,i),A/'tiles'/n)
wet=Image.new('RGBA',(96,64),(0,0,0,0)); d=ImageDraw.Draw(wet,'RGBA')
for y in [22,31,40]: d.arc((15,y-8,81,y+8),5,175,fill=(125,224,255,120),width=2)
S(wet,A/'tiles'/'wet-overlay-placeholder.png')
e=Image.new('RGBA',(96,64),(0,0,0,0)); d=ImageDraw.Draw(e,'RGBA'); d.line([(20,31),(36,22),(33,31),(53,20),(47,35),(74,27)],fill=(255,242,94,215),width=3); S(e,A/'tiles'/'electrified-overlay-placeholder.png')
ALIA={'grass-tile.png':'grass.png','dirt-tile.png':'scorched_dirt.png','road-tile.png':'road.png','stone-tile.png':'stone.png','wall-tile.png':'wall-tile-placeholder.png','shallow-water-tile.png':'shallow_water.png','shrine-tile.png':'holy_shrine.png','high-ground-tile.png':'cliff_grass.png','brush-tile.png':'brush.png','grass-flowers-tile.png':'grass_flowers.png','burning-tile.png':'burning_grass.png','frozen-tile.png':'frozen_water.png','cracked-stone-tile.png':'cracked_stone.png','height-edge-grass.png':'cliff_grass.png','height-edge-stone.png':'stone.png','wet-overlay.png':'wet-overlay-placeholder.png','electrified-overlay.png':'electrified-overlay-placeholder.png'}
for dst,src in ALIA.items(): S(Image.open(A/'tiles'/src).convert('RGBA'),A/'tiles'/dst)
def prop(kind):
 im=Image.new('RGBA',(96,96),(0,0,0,0)); d=ImageDraw.Draw(im,'RGBA'); d.ellipse((20,66,78,82),fill=(0,0,0,45))
 if kind=='rock': d.polygon([(28,55),(39,33),(62,28),(76,48),(66,67),(38,69)],fill=(91,95,87,255),outline=(40,43,39,255)); d.polygon([(39,33),(62,28),(55,48),(31,55)],fill=(132,137,124,255)); [d.ellipse((x-5,y-3,x+5,y+3),fill=(71,116,63,180)) for x,y in [(43,45),(51,57),(59,38)]]
 if kind=='bush':
  for box,col in [((24,44,51,71),(40,101,47,255)),((42,35,72,68),(54,128,58,255)),((31,29,58,62),(70,151,65,255)),((51,49,78,74),(34,91,47,255))]: d.ellipse(box,fill=col,outline=adj(col,-35))
  [d.ellipse((x-1,y-1,x+1,y+1),fill=(245,218,126,210)) for x,y in [(42,45),(54,52),(36,58),(61,42)]]
 if kind=='stump': d.rectangle((34,38,63,68),fill=(105,68,40,255),outline=(59,39,27,255)); d.ellipse((32,29,65,46),fill=(150,102,58,255),outline=(64,43,27,255)); d.ellipse((41,34,56,42),outline=(80,52,30,190),width=2)
 if kind=='ruin': d.polygon([(31,30),(66,24),(75,60),(38,70)],fill=(92,95,96,255),outline=(39,42,45,255)); d.polygon([(31,30),(66,24),(60,42),(35,47)],fill=(132,136,135,255)); d.line((41,35,50,64),fill=(42,44,47,150),width=2); d.line((57,29,70,55),fill=(42,44,47,150),width=2)
 return im
for n,k in {'mossy_rock.png':'rock','leafy_bush.png':'bush','tree_stump.png':'stump','ruin_block.png':'ruin'}.items(): S(prop(k),A/'props'/n)
for dst,src in {'mossy-rock.png':'mossy_rock.png','leafy-bush.png':'leafy_bush.png','tree-stump.png':'tree_stump.png','ruin-block.png':'ruin_block.png','broken-banner.png':'tree_stump.png','ash-pillar.png':'ruin_block.png'}.items(): S(Image.open(A/'props'/src),A/'props'/dst)
def unit(pal,role):
 im=Image.new('RGBA',(128,128),(0,0,0,0)); d=ImageDraw.Draw(im,'RGBA'); d.ellipse((39,97,91,112),fill=(0,0,0,70)); skin=pal.get('skin',(224,171,122,255)); cloth=pal.get('cloth',(80,110,160,255)); trim=pal.get('trim',(225,190,89,255)); hair=pal.get('hair',(60,45,35,255)); metal=(182,188,194,255)
 if role=='drake': d.ellipse((34,56,92,100),fill=cloth,outline=adj(cloth,-55),width=2); d.polygon([(49,60),(31,42),(58,49)],fill=adj(cloth,28),outline=adj(cloth,-50)); d.polygon([(76,60),(98,42),(70,49)],fill=adj(cloth,28),outline=adj(cloth,-50)); d.polygon([(54,54),(64,30),(76,55)],fill=adj(cloth,42),outline=adj(cloth,-50)); d.ellipse((56,50,76,70),fill=adj(cloth,25),outline=adj(cloth,-55)); d.ellipse((61,57,64,60),fill=(220,250,255,255)); d.ellipse((70,57,73,60),fill=(220,250,255,255))
 elif role=='wraith': d.polygon([(64,24),(88,99),(64,111),(40,99)],fill=cloth,outline=adj(cloth,-50)); d.ellipse((49,31,79,62),fill=adj(cloth,22),outline=adj(cloth,-50)); d.ellipse((56,44,60,49),fill=trim); d.ellipse((69,44,73,49),fill=trim); d.arc((42,78,86,124),205,335,fill=trim[:3]+(180,),width=3)
 else:
  d.polygon([(48,64),(80,64),(89,100),(39,100)],fill=cloth,outline=adj(cloth,-55),width=2); d.ellipse((50,36,78,65),fill=skin,outline=(92,55,42,255),width=2); d.pieslice((47,29,81,54),180,360,fill=hair); d.rectangle((55,62,73,77),fill=trim); d.line((42,70,23,88),fill=metal if role in ['knight','archer'] else trim,width=5); d.line((84,70,104,84),fill=metal if role in ['knight','archer'] else trim,width=5)
  if role=='mage': d.line((93,50,99,93),fill=(96,62,42,255),width=4); d.ellipse((90,43,102,55),fill=trim)
  if role=='archer': d.arc((20,52,50,101),260,100,fill=(126,80,40,255),width=3)
  if role=='knight': d.polygon([(94,55),(112,68),(94,81)],fill=metal,outline=(78,82,86,255))
 return im.filter(ImageFilter.UnsharpMask(radius=1,percent=110,threshold=3))
U={'zane':({'cloth':(62,84,132,255),'trim':(222,186,90,255),'hair':(53,38,29,255)},'knight'),'mira':({'cloth':(118,62,150,255),'trim':(124,219,255,255),'hair':(35,30,58,255)},'mage'),'kael':({'cloth':(145,61,44,255),'trim':(220,162,74,255),'hair':(207,158,69,255)},'knight'),'lyra':({'cloth':(53,118,92,255),'trim':(214,226,118,255),'hair':(226,196,123,255)},'archer'),'storm_imp':({'cloth':(66,91,158,255),'trim':(255,237,93,255)},'wraith'),'void_cultist':({'cloth':(61,32,88,255),'trim':(203,81,255,255),'skin':(154,134,174,255)},'mage'),'null_drake':({'cloth':(55,42,82,255),'trim':(107,220,255,255)},'drake'),'fen_wraith':({'cloth':(45,78,66,230),'trim':(148,255,202,255)},'wraith'),'ashen_soldier':({'cloth':(91,73,66,255),'trim':(229,100,64,255),'hair':(54,50,48,255)},'knight'),'bone_archer':({'cloth':(82,88,78,255),'trim':(223,218,184,255),'skin':(210,202,174,255)},'archer'),'cult_mage':({'cloth':(80,41,70,255),'trim':(255,76,112,255),'skin':(182,156,160,255)},'mage'),'boss_null_knight':({'cloth':(42,34,56,255),'trim':(236,58,88,255),'skin':(166,159,181,255)},'knight')}
for n,(p,r) in U.items():
 im=unit(p,r); S(im,A/'sprites'/'units'/f'{n}.png'); hy=n.replace('_','-'); S(im,A/'sprites'/'units'/f'{hy}-idle-isometric.png'); S(im,A/'sprites'/'units'/f'{hy}-action-isometric.png')
for n,(p,r) in {'fen-wraith-idle-placeholder':U['fen_wraith'],'fen-wraith-attack-placeholder':U['fen_wraith'],'siren-guardian-summon':({'cloth':(46,126,156,255),'trim':(187,246,255,255)},'wraith'),'titan-guardian-summon':({'cloth':(107,84,58,255),'trim':(241,196,96,255)},'drake')}.items(): S(unit(p,r),A/'generated'/'characters'/f'{n}.png')
def icon(sym,fg,bg=(35,39,48,255),sz=64):
 im=Image.new('RGBA',(sz,sz),(0,0,0,0)); d=ImageDraw.Draw(im,'RGBA'); d.rounded_rectangle((4,4,sz-5,sz-5),radius=10,fill=bg,outline=adj(bg,45),width=2)
 if sym=='sword': d.line((20,44,44,20),fill=fg,width=5); d.line((34,18,46,18),fill=fg,width=3); d.line((18,46,26,54),fill=(120,78,43,255),width=4)
 elif sym=='boot': d.polygon([(21,20),(36,21),(36,39),(49,42),(48,50),(20,50)],fill=fg,outline=adj(fg,-50))
 elif sym=='spark': d.polygon([(32,11),(38,27),(54,31),(39,37),(32,54),(26,38),(10,32),(26,26)],fill=fg,outline=(255,255,255,120))
 elif sym=='bag': d.ellipse((22,13,42,27),outline=fg,width=3); d.rounded_rectangle((18,24,47,52),radius=7,fill=fg,outline=adj(fg,-50))
 elif sym=='hour': d.polygon([(21,13),(43,13),(36,31),(43,51),(21,51),(28,31)],outline=fg,width=3); d.polygon([(28,21),(36,21),(32,29)],fill=fg); d.polygon([(26,47),(38,47),(32,37)],fill=fg)
 elif sym=='shield': d.polygon([(32,11),(50,19),(46,39),(32,54),(18,39),(14,19)],fill=fg,outline=(255,255,255,100))
 elif sym=='bow': d.arc((18,10,44,54),270,90,fill=fg,width=4); d.line((39,14,39,50),fill=(236,229,197,255),width=2); d.line((24,35,48,29),fill=fg,width=3)
 elif sym=='cross': d.rounded_rectangle((28,12,36,52),radius=3,fill=fg); d.rounded_rectangle((14,26,50,34),radius=3,fill=fg)
 elif sym=='dagger': d.polygon([(34,11),(43,35),(33,53),(24,35)],fill=fg); d.line((20,36,48,36),fill=adj(fg,45),width=3)
 elif sym=='flame': d.polygon([(32,10),(45,34),(35,54),(22,45),(24,30)],fill=fg,outline=adj(fg,-40)); d.polygon([(33,27),(39,39),(31,50),(26,40)],fill=(255,217,86,230))
 elif sym=='ice': d.line((32,11,32,53),fill=fg,width=4); d.line((14,22,50,42),fill=fg,width=4); d.line((14,42,50,22),fill=fg,width=4)
 elif sym=='skull': d.ellipse((18,13,46,42),fill=fg,outline=adj(fg,-60)); d.rectangle((25,38,39,52),fill=fg); d.ellipse((25,25,30,31),fill=bg); d.ellipse((36,25,41,31),fill=bg)
 elif sym=='coin': d.ellipse((14,14,50,50),fill=fg,outline=adj(fg,-55),width=3); d.ellipse((23,23,41,41),outline=(255,255,255,120),width=2)
 elif sym=='bolt': d.line([(25,10),(39,29),(32,30),(42,54),(24,32),(32,31)],fill=fg,width=5)
 else: d.ellipse((17,17,47,47),fill=fg,outline=(255,255,255,120),width=2)
 return im
ICON={'command-attack-icon.png':('sword',(236,92,72,255)),'command-move-icon.png':('boot',(77,185,243,255)),'command-ability-icon.png':('spark',(176,105,255,255)),'command-item-icon.png':('bag',(229,181,87,255)),'command-wait-icon.png':('hour',(184,188,197,255)),'job-knight-icon.png':('shield',(104,148,224,255)),'job-mage-icon.png':('spark',(177,95,248,255)),'job-archer-icon.png':('bow',(98,192,112,255)),'job-guardian-icon.png':('shield',(229,186,84,255)),'job-cleric-icon.png':('cross',(238,232,173,255)),'job-rogue-icon.png':('dagger',(134,138,160,255)),'status-burn-icon.png':('flame',(241,87,42,255)),'status-freeze-icon.png':('ice',(139,223,255,255)),'status-slow-icon.png':('hour',(123,168,221,255)),'status-curse-icon.png':('skull',(169,87,216,255)),'status-bleed-icon.png':('dagger',(220,58,75,255)),'status-shield-icon.png':('shield',(106,174,235,255)),'run-node-battle-icon.png':('sword',(229,91,69,255)),'run-node-elite-icon.png':('spark',(255,184,74,255)),'run-node-boon-icon.png':('cross',(222,213,129,255)),'run-node-wanderer-icon.png':('spark',(108,219,171,255)),'run-node-boss-icon.png':('skull',(236,61,87,255)),'run-node-shop-icon.png':('bag',(229,181,87,255)),'currency-soul-shards-icon.png':('coin',(134,209,255,255)),'currency-obsidian-icon.png':('coin',(70,61,84,255)),'currency-glyphs-icon.png':('coin',(193,126,255,255)),'currency-boss-tokens-icon.png':('coin',(239,70,88,255)),'currency-phoenix-sigils-icon.png':('flame',(255,114,53,255)),'currency-titan-sigils-icon.png':('shield',(219,176,92,255)),'boon-phoenix-heart-icon.png':('flame',(255,92,52,255)),'boon-ember-reprisal-icon.png':('sword',(255,121,61,255)),'boon-titan-bulwark-icon.png':('shield',(206,161,82,255)),'boon-stone-oath-icon.png':('shield',(149,154,150,255)),'boon-storm-quickening-icon.png':('bolt',(255,238,84,255)),'boon-void-bargain-icon.png':('skull',(188,87,255,255)),'guardian-phoenix-sigil.png':('flame',(255,100,48,255)),'guardian-titan-sigil.png':('shield',(214,174,92,255)),'guardian-storm-sigil.png':('bolt',(255,238,84,255)),'guardian-void-sigil.png':('skull',(190,91,255,255)),'affix-volatile-icon.png':('flame',(255,118,46,255)),'affix-fortified-icon.png':('shield',(154,164,177,255)),'affix-vampiric-icon.png':('skull',(203,54,88,255)),'affix-of-frost-icon.png':('ice',(132,222,255,255)),'affix-of-flames-icon.png':('flame',(246,88,44,255)),'affix-of-void-icon.png':('spark',(181,87,255,255))}
for n,(s,c) in ICON.items(): S(icon(s,c),A/'generated'/'icons'/n)
def panel(base,trim,size):
 im=Image.new('RGBA',size,(0,0,0,0)); d=ImageDraw.Draw(im,'RGBA'); w,h=size; d.rounded_rectangle((3,3,w-4,h-4),radius=8,fill=base,outline=trim,width=3); d.rounded_rectangle((10,10,w-11,h-11),radius=5,outline=trim[:3]+(95,),width=1); return im
for n,b,t,z in [('command-bar-panel.png',(25,28,34,235),(215,174,86,255),(420,92)),('dark-stone-panel.png',(27,30,38,235),(100,112,126,255),(260,120)),('turn-order-sidebar-panel.png',(22,24,31,235),(204,178,116,255),(112,420)),('hp-bar-frame.png',(52,24,29,230),(219,71,72,255),(180,28)),('temper-bar-frame.png',(55,42,20,230),(235,177,74,255),(180,28)),('ether-bar-frame.png',(24,41,57,230),(77,191,230,255),(180,28)),('hub-panel-dark-gold.png',(28,25,24,238),(222,170,69,255),(320,150)),('guardian-shrine-panel.png',(25,31,38,238),(126,214,226,255),(320,150)),('job-reliquary-panel.png',(32,29,40,238),(186,151,226,255),(320,150)),('heat-altar-panel.png',(42,24,20,238),(238,95,59,255),(320,150)),('reward-card-panel.png',(31,29,25,238),(227,198,117,255),(220,132))]: S(panel(b,t,z),A/'generated'/'ui'/n)
for n,c in {'tile-selected-diamond.png':(255,240,130,150),'tile-move-diamond.png':(80,190,255,125),'tile-attack-diamond.png':(255,82,86,135),'tile-ability-diamond.png':(181,95,255,135),'tile-blocked-diamond.png':(50,50,55,150)}.items(): im=Image.new('RGBA',(96,64),(0,0,0,0)); d=ImageDraw.Draw(im,'RGBA'); d.polygon(dia(),fill=c,outline=c[:3]+(230,)); S(im,A/'generated'/'ui'/n)
def vfx(kind,c1,c2):
 im=Image.new('RGBA',(256,64),(0,0,0,0));
 for i in range(4):
  d=ImageDraw.Draw(im,'RGBA'); ox=i*64; cx=ox+32; cy=32; r=10+i*6
  if kind=='slash': d.arc((ox+8,8,ox+56,56),210-i*8,330+i*8,fill=c1,width=3+i); d.arc((ox+13,12,ox+51,52),205,325,fill=c2,width=2)
  elif kind=='bolt': d.line([(cx-12,8),(cx+1,25),(cx-7,27),(cx+12,56),(cx+4,34),(cx+14,32)],fill=c1,width=4+i); d.line([(cx-7,10),(cx+7,31),(cx-2,31),(cx+9,54)],fill=c2,width=2)
  else: d.ellipse((cx-r,cy-r,cx+r,cy+r),outline=c1,width=3+i); d.ellipse((cx-r//2,cy-r//2,cx+r//2,cy+r//2),fill=c2)
 return im
for n,k,c1,c2 in [('damage-number-floats.png','slash',(255,235,147,230),(255,90,76,180)),('earth-impact-vfx-sheet.png','burst',(181,129,70,220),(92,64,42,150)),('fire-impact-vfx-sheet.png','burst',(255,101,44,230),(255,213,79,180)),('ice-impact-vfx-sheet.png','burst',(132,224,255,230),(240,252,255,180)),('lightning-impact-vfx-sheet.png','bolt',(255,241,83,240),(132,220,255,190)),('wind-impact-vfx-sheet.png','slash',(154,255,209,220),(216,255,239,150)),('dark-impact-vfx-sheet.png','burst',(176,78,255,230),(44,22,68,190)),('holy-impact-vfx-sheet.png','burst',(255,241,164,235),(255,255,255,190)),('heal-vfx-sheet.png','burst',(115,240,163,230),(226,255,224,180)),('buff-vfx-sheet.png','burst',(130,179,255,230),(229,240,255,180))]: S(vfx(k,c1,c2),A/'generated'/'vfx'/n)
print('demo asset pack complete')
