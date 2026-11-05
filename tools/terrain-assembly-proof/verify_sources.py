"""Read-only source integrity checks; never modifies PNG pixels."""
import hashlib,json,pathlib
p=pathlib.Path(__file__).parent
meta=json.loads((p/'proposed-registration.json').read_text())
assert meta['approval']=='none'
assert meta['tile_size']==[96,48]
for key,a in meta['assets'].items():
    assert hashlib.sha256((p/'assets'/a['file']).read_bytes()).hexdigest()==a['sha256'], key
print('PASS: four original PNG hashes unchanged; registration unapproved')
