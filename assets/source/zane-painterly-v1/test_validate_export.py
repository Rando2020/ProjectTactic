"""Regression test: failed clearance must not publish a compatible-looking report."""
import importlib.util,json,shutil,tempfile,unittest
from pathlib import Path
from unittest.mock import patch
HERE=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('candidate_validator',HERE/'validate_export.py');module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
class FailureReporting(unittest.TestCase):
 def test_atlas_import_is_lossless_mipmapped_and_stable_in_3d(self):
  settings=(module.OUT/'zane_painterly_v1_zane_painterly_atlas.png.import').read_text()
  self.assertRegex(settings,r'(?m)^compress/mode=0$')
  self.assertRegex(settings,r'(?m)^detect_3d/compress_to=0$')
  self.assertRegex(settings,r'(?m)^mipmaps/generate=true$')
  self.assertIn('"vram_texture": false',settings)
  self.assertNotIn('.s3tc.ctex',settings)
 def test_floor_failure_is_explicit_and_metadata_not_rewritten(self):
  metadata=module.OUT/'presentation.json';before=metadata.read_bytes()
  with tempfile.TemporaryDirectory() as d:
   temporary=Path(d);(temporary/'textures').mkdir();shutil.copy(HERE/'textures/zane_painterly_atlas.png',temporary/'textures/zane_painterly_atlas.png')
   with patch.object(module,'HERE',temporary),patch.object(module.v,'exported_motion_report',return_value={'minimum_exported_vertex_y':{'defeat':-.1034}}):
    with self.assertRaisesRegex(AssertionError,'unchanged floor tolerance'):module.validate(write_metadata=True)
   report=json.loads((temporary/'validation_report.json').read_text());self.assertEqual(report['status'],'failed-floor-clearance');self.assertIn('failure',report)
  self.assertEqual(metadata.read_bytes(),before)
if __name__=='__main__':unittest.main()
