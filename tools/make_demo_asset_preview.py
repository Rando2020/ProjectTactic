from pathlib import Path
from PIL import Image, ImageDraw
ROOT=Path(r'C:\Users\jojo3\Coding\ProjectTactic')
items=[]
for folder,names in [
 ('godot/assets/tiles',['grass.png','road.png','stone.png','shallow_water.png','burning_grass.png','holy_shrine.png','boss-arena-tile.png','void-corruption-tile.png']),
 ('godot/assets/props',['mossy_rock.png','leafy_bush.png','tree_stump.png','ruin_block.png']),
 ('godot/assets/sprites/units',['zane.png','mira.png','kael.png','lyra.png','storm_imp.png','void_cultist.png','null_drake.png','boss_null_knight.png']),
 ('godot/assets/generated/icons',['command-attack-icon.png','command-move-icon.png','job-knight-icon.png','boon-phoenix-heart-icon.png','run-node-boss-icon.png','status-burn-icon.png'])]:
 for n in names:
  p=ROOT/folder/n
  if p.exists(): items.append((p,n))
cell=128; cols=6; rows=(len(items)+cols-1)//cols
out=Image.new('RGBA',(cols*cell,rows*cell),(24,25,30,255)); d=ImageDraw.Draw(out)
for i,(p,n) in enumerate(items):
 im=Image.open(p).convert('RGBA')
 im.thumbnail((96,82), Image.Resampling.LANCZOS)
 x=(i%cols)*cell+(cell-im.width)//2; y=(i//cols)*cell+10
 out.alpha_composite(im,(x,y)); d.text(((i%cols)*cell+8,(i//cols)*cell+98),n[:19],fill=(230,220,190,255))
out.save(ROOT/'godot/assets/generated/demo_asset_preview.png')
print(ROOT/'godot/assets/generated/demo_asset_preview.png')
