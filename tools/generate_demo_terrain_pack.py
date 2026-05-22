from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
GODOT = ROOT / 'godot' / 'assets'

TILES = {
    'grass-tile.png': ((74, 112, 67), (122, 168, 104)),
    'dirt-tile.png': ((115, 86, 62), (172, 132, 97)),
    'road-tile.png': ((98, 92, 84), (188, 168, 126)),
    'stone-tile.png': ((82, 82, 90), (165, 164, 148)),
    'wall-tile.png': ((64, 66, 74), (145, 145, 133)),
    'shallow-water-tile.png': ((47, 95, 116), (119, 196, 214)),
    'shrine-tile.png': ((84, 79, 97), (228, 209, 138)),
    'high-ground-tile.png': ((73, 91, 65), (182, 176, 121)),
    'height-edge-grass.png': ((56, 74, 52), (129, 168, 96)),
    'height-edge-stone.png': ((74, 74, 79), (161, 160, 149)),
    'brush-tile.png': ((55, 96, 64), (122, 186, 112)),
    'grass-flowers-tile.png': ((76, 116, 72), (206, 184, 214)),
    'burning-tile.png': ((117, 58, 33), (241, 124, 62)),
    'frozen-tile.png': ((133, 172, 190), (219, 243, 255)),
    'cracked-stone-tile.png': ((81, 81, 84), (164, 155, 142)),
    'void-corruption-tile.png': ((52, 36, 72), (164, 96, 205)),
    'elite-spawn-tile.png': ((92, 42, 52), (235, 170, 83)),
    'boss-arena-tile.png': ((43, 41, 47), (209, 64, 72)),
}

PROPS = {
    'leafy-bush.png': (79, 132, 74),
    'ruin-block.png': (112, 112, 104),
    'mossy-rock.png': (91, 98, 89),
    'tree-stump.png': (126, 92, 61),
    'broken-banner.png': (151, 58, 62),
    'ash-pillar.png': (88, 87, 93),
}

OVERLAYS = {
    'elite-overlay-marked.png': (255, 190, 82),
    'elite-overlay-champion.png': (255, 104, 104),
}


def ensure(path: Path):
    path.parent.mkdir(parents=True, exist_ok=True)


def save(img: Image.Image, path: Path):
    ensure(path)
    img.save(path)
    print(path.relative_to(ROOT).as_posix())


def iso_tile(base, accent):
    img = Image.new('RGBA', (128, 96), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    pts = [(64, 8), (120, 48), (64, 88), (8, 48)]
    d.polygon(pts, fill=base)
    d.line(pts + [pts[0]], fill=accent, width=3)
    for y in range(18, 70, 10):
        d.line((24, y, 64, y + 18, 104, y), fill=accent, width=1)
    return img


def prop_icon(color):
    img = Image.new('RGBA', (96, 96), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse((18, 18, 78, 78), fill=color)
    d.rectangle((42, 58, 54, 88), fill=(66, 48, 34))
    return img


def overlay(color):
    img = Image.new('RGBA', (128, 96), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    pts = [(64, 8), (120, 48), (64, 88), (8, 48)]
    d.polygon(pts, fill=(*color, 90))
    d.line(pts + [pts[0]], fill=(*color, 220), width=4)
    return img


for name, (base, accent) in TILES.items():
    save(iso_tile(base, accent), GODOT / 'tiles' / name)

for name, color in PROPS.items():
    save(prop_icon(color), GODOT / 'props' / name)

for name, color in OVERLAYS.items():
    save(overlay(color), GODOT / 'overlays' / name)
