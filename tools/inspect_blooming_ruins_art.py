"""Inspect generated atlas alpha and write regions; never modifies image pixels."""
import hashlib
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1] / 'godot/assets/environments/blooming-ruins-v2'
# Manually inspected regions: generated sheets are NOT assumed to be regular grids.
REGIONS = {
    'foliage.png': {
        'cypress': (100, 0, 430, 565),
        'pink-shrub': (520, 130, 1020, 565),
        'pink-flowers': (1050, 220, 1536, 565),
        'hanging-ivy': (20, 565, 520, 1024),
        'grass': (580, 610, 1000, 970),
        'cream-shrub': (1020, 630, 1536, 1024),
    },
    'architecture.png': {
        'column': (200, 0, 550, 550),
        'broken-column': (850, 180, 1200, 550),
        'ruined-pier': (200, 560, 560, 1145),
        'arch': (700, 550, 1374, 1145),
    },
    'props.png': {
        'banner': (190, 0, 680, 550),
        'pots': (820, 90, 1380, 530),
        'rubble': (120, 560, 730, 1024),
        'low-wall': (760, 530, 1536, 1024),
    },
}

report = {'assets': [], 'tool': 'built-in image_gen', 'status': 'generated; preview acceptance required',
          'camera': 'fixed isometric, approximately 30 degrees down',
          'tile_world_units': 2, 'collision': 'decorative cutouts have no collision; gameplay owns occupancy',
          'characters': 'reuse ProjectTactic asset_manifest.json; no new character canon in this pack'}
for filename in ['surfaces.png', 'foliage.png', 'architecture.png', 'props.png', 'distance.png']:
    path = ROOT / filename
    image = Image.open(path)
    entry = {'file': filename, 'size': list(image.size), 'mode': image.mode,
             'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}
    if filename in REGIONS:
        alpha = image.getchannel('A')
        histogram = alpha.histogram()
        assert histogram[0] > image.width * image.height * .1, filename + ': missing clear background'
        assert sum(histogram[128:]) > 1000, filename + ': missing visible silhouettes'
        entry['transparent_fraction'] = round(histogram[0] / (image.width * image.height), 4)
        entry['regions'] = {}
        for asset_id, bounds in REGIONS[filename].items():
            mask = alpha.crop(bounds).point(lambda a: 255 if a >= 128 else 0)
            bbox = mask.getbbox()
            assert bbox, asset_id
            x0, y0 = bounds[0] + bbox[0], bounds[1] + bbox[1]
            x1, y1 = bounds[0] + bbox[2], bounds[1] + bbox[3]
            entry['regions'][asset_id] = {'rect': [x0, y0, x1-x0, y1-y0],
                'pivot': 'top-center' if asset_id == 'hanging-ivy' else 'bottom-center',
                'collision': 'none', 'alpha_cutoff': .5}
    report['assets'].append(entry)
report['surface_quadrants'] = ['paving', 'ochre-soil', 'masonry', 'coping-and-stairs']
report['limits'] = ['Seamless repetition not guaranteed by generation; inspect repeated materials.',
                    'Not meshes or animation frames; cutouts require a fixed camera.',
                    'Do not rasterize UI text; use the supplied Godot theme.']
(ROOT / 'manifest.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
print(json.dumps({'files': len(report['assets']), 'cutouts': sum(len(a.get('regions', {})) for a in report['assets']),
                  'alpha_validation': 'passed'}, indent=2))
