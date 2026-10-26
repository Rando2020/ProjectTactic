"""Source-level regression checks for the bounded illustrated-Zane asset contract.

These do not substitute for a Godot import or human visual acceptance.
"""
import json
import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
GODOT = ROOT / "godot"


class IllustratedZaneContractTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.manifest = json.loads((GODOT / "data/asset_manifest.json").read_text(encoding="utf-8"))
        cls.asset_registry = (GODOT / "scripts/data/AssetRegistry.gd").read_text(encoding="utf-8")
        cls.unit = (GODOT / "scripts/units/Unit.gd").read_text(encoding="utf-8")
        cls.character = (GODOT / "scripts/ui/CharacterScreen.gd").read_text(encoding="utf-8")
        cls.battle_ui = (GODOT / "scripts/battle/BattleUI.gd").read_text(encoding="utf-8")
        cls.manager = (GODOT / "scripts/battle/BattleManager.gd").read_text(encoding="utf-8")

    def test_only_zane_has_new_direction_manifest(self):
        characters = self.manifest["characters"]
        self.assertEqual({"front", "right", "back", "left"}, set(characters["zane"]["directions"]))
        for unit_id, spec in characters.items():
            if unit_id != "zane":
                self.assertNotIn("directions", spec)

    def test_assets_have_stable_fallbacks(self):
        character = self.manifest["characters"]["zane"]
        for spec in [character["portrait"], *character["directions"].values()]:
            self.assertTrue(spec["path"].startswith("res://assets/"))
            fallback = spec["fallback_path"]
            self.assertTrue(fallback.startswith("res://assets/"))
            self.assertTrue((GODOT / fallback.removeprefix("res://")).is_file(), fallback)
        self.assertIn("zane-portrait-illustrated.jpg", character["portrait"]["path"])

    def test_resolution_independent_from_battle_logic(self):
        self.assertIn("func get_character_portrait_candidates(", self.asset_registry)
        self.assertIn("func get_character_direction_candidates(", self.asset_registry)
        self.assertIn('_character_direction_texture(facing)', self.unit)
        self.assertIn('_refresh_directional_sprite()', self.unit)
        self.assertIn('unit_data.id != "zane"', self.unit)
        self.assertIn('get_character_portrait_candidates(uid)', self.character)
        self.assertIn('get_character_portrait_candidates(unit.unit_data.id)', self.manager)
        self.assertIn('get_character_portrait_candidates(unit.unit_data.id)', self.battle_ui)

    def test_frozen_rigs_are_untouched(self):
        for model in ["zane_v2", "zane_impact_v1", "zane_painterly_v1"]:
            self.assertTrue((GODOT / "assets/3d/characters" / model).is_dir())


if __name__ == "__main__":
    unittest.main()
