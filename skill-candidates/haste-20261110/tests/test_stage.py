import hashlib
import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

KIT = Path(__file__).resolve().parents[1]
ROOT = KIT.parents[1]

class StageTest(unittest.TestCase):
    def test_isolated_skill_candidate_is_available(self):
        self.assertTrue((KIT / 'stage.py').is_file(), 'missing isolated skill candidate stager')
        spec = importlib.util.spec_from_file_location('stage_haste', KIT / 'stage.py')
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        source = ROOT / 'demos/isometric-2v2'
        originals = {p: p.read_bytes() for p in (source / 'project.godot', source / 'prototypes/blooming/BloomingBattle.tscn', source / 'scripts/data/AbilityDB.gd')}
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp) / 'candidate'
            module.stage(target)
            self.assertIn('ProjectTactic-HasteCandidate-20261110', (target / 'project.godot').read_text())
            self.assertIn('candidate_skills/HasteVFX.gd', (target / 'project.godot').read_text())
            self.assertIn('candidate_skills/SkillBattle.gd', (target / 'prototypes/blooming/BloomingBattle.tscn').read_text())
            self.assertEqual(hashlib.sha256((target / 'candidate_skills/haste-aura.png').read_bytes()).hexdigest(), module.ART_SHA)
            self.assertEqual((target / 'scripts/data/AbilityDB.gd').read_bytes(), originals[source / 'scripts/data/AbilityDB.gd'])
            with self.assertRaises(FileExistsError):
                module.stage(target)
        for path, data in originals.items():
            self.assertEqual(path.read_bytes(), data, str(path))

    def test_refuses_source_or_parent_destination(self):
        self.assertTrue((KIT / 'stage.py').is_file(), 'missing isolated skill candidate stager')
        spec = importlib.util.spec_from_file_location('stage_haste', KIT / 'stage.py')
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        for target in [ROOT, ROOT / 'demos', ROOT / 'demos/isometric-2v2', ROOT / 'demos/isometric-2v2/candidate']:
            with self.assertRaises((ValueError, FileExistsError)):
                module.stage(target)

    def test_refuses_destination_inside_candidate_inputs_before_copying(self):
        spec = importlib.util.spec_from_file_location('stage_haste', KIT / 'stage.py')
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        with patch.object(module.shutil, 'copytree', side_effect=RuntimeError('write reached')):
            caught = None
            try:
                module.stage(KIT / 'runtime/nested-output')
            except Exception as error:
                caught = error
            self.assertIsInstance(caught, ValueError, 'input-destination guard must reject before copying')

if __name__ == '__main__': unittest.main()
