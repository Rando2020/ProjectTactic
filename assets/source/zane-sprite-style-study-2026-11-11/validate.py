"""Read-only validation of the source-only style study; not an animation test."""
from pathlib import Path
from hashlib import sha256
import json
from PIL import Image

root = Path(__file__).resolve().parent
manifest = json.loads((root / 'manifest.json').read_text())
assert manifest['study_only'] is True
assert len(manifest['sources']) == 3
assert len([s for s in manifest['sources'] if s['candidate']]) == 2
for item in manifest['sources']:
    path = root / item['file']
    assert sha256(path.read_bytes()).hexdigest() == item['sha256'], path
    with Image.open(path) as im:
        assert im.mode == 'RGBA', path
        assert im.size == (item['width'], item['height']), path
        alpha = im.getchannel('A')
        bounds = alpha.point(lambda n: 255 if n >= 128 else 0).getbbox()
        assert list(bounds) == item['alpha_bounds_128'], path
        left, top, right, bottom = bounds
        assert min(left, top, im.width-right, im.height-bottom) >= 16, path
        hist = alpha.histogram()
        assert hist[0] > im.width*im.height*0.5, path
        assert sum(hist[128:]) > 10000, path
    assert item['animation_frames'] == 1 and item['flip_h'] is False
    assert item['accepted_for_gameplay'] is False
assert manifest['sources'][0]['sha256'] == 'd299d45c28f164620beee1d88871edea780ce4ad3c4873f1bea86735b64ab236'
for name in ['README.md', 'qa.md', 'prompts.json', 'review.html', 'evidence/style-comparison.png', 'evidence/Zane-Sprite-Comparison.pdf']:
    assert (root / name).is_file() and (root / name).stat().st_size > 0, name
with Image.open(root / 'evidence/style-comparison.png') as im:
    assert im.size == (1260, 820)
assert (root / 'evidence/Zane-Sprite-Comparison.pdf').read_bytes().startswith(b'%PDF-')
print('PASS: 3 RGBA PNGs, exact hashes/dimensions/alpha bounds, transparent margins, 2 unapproved one-pose candidates, comparison evidence present.')
print('NOT TESTED: native pixel grid, multi-direction continuity, animation, gameplay registration or engine integration.')
