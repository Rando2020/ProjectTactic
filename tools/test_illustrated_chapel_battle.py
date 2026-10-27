"""First playable illustrated chapel slice source contracts (no engine needed)."""

import json
from pathlib import Path
import re
import unittest
from xml.etree import ElementTree

ROOT = Path(__file__).resolve().parents[1]
GODOT = ROOT / "godot"


class IllustratedChapelContracts(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.manifest = json.loads((GODOT / "data/asset_manifest.json").read_text())
        cls.scene = (GODOT / "scripts/battle/BattleScene.gd").read_text()
        cls.ui = (GODOT / "scripts/battle/BattleUI.gd").read_text()
        cls.state = (GODOT / "scripts/systems/GameState.gd").read_text()
        cls.start = (GODOT / "scripts/ui/StartScreen.gd").read_text()

    def test_art_is_real_independent_svg_and_bounds(self):
        chapel = self.manifest["environments"]["ruined-chapel"]
        names = list(chapel["terrain"].values()) + list(chapel["props"].values())
        self.assertGreaterEqual(len(names), 8)
        for entry in names:
            path = entry["path"].removeprefix("res://")
            full = GODOT / path
            self.assertTrue(full.is_file(), full)
            svg = ElementTree.parse(full).getroot()
            self.assertTrue(svg.tag.endswith("svg"))
            self.assertGreater(int(svg.attrib["width"]), 0)
            self.assertGreater(int(svg.attrib["height"]), 0)

    def test_new_practice_path_preserves_existing_duel(self):
        self.assertIn('practice_session["illustrated_chapel"] = true', self.state)
        self.assertIn('begin_zane_duel_practice()', self.state)
        self.assertIn("Illustrated Chapel / Play 2.5D Battle", self.start)
        self.assertIn('GameState.begin_illustrated_chapel_practice()', self.start)
        self.assertIn('practice_session.get("illustrated_chapel", false)', self.scene)
        self.assertIn("func _create_illustrated_chapel_map()", self.scene)
        self.assertIn("func _create_ashvale_map()", self.scene)

    def test_chapel_buttons_are_real_not_proxy_combat(self):
        for button in ["_move_btn", "_attack_btn", "_ability_btn", "_wait_btn"]:
            self.assertIn("button.reparent(_chapel_command_buttons)", self.ui)
            self.assertIn(button, self.ui)
        self.assertIn("not is_instance_valid(_chapel_command_panel)", self.ui)
        self.assertIn("func _on_action_preview_changed(preview: Dictionary)", self.ui)
        self.assertNotIn("red_fullscreen_chapel", self.ui)

    def test_existing_forecast_is_neutral_not_screen_tint(self):
        self.assertIn("st.bg_color = Color(0.035, 0.038, 0.052, 0.92)", self.ui)
        self.assertIn("func _build_action_preview_panel()", self.ui)
        self.assertIn("_preview_actor_portrait", self.ui)
        self.assertIn("_preview_target_portrait", self.ui)
        # Fire and Hit chance still originate from the canonical forecast.
        self.assertIn('preview.get("hit_pct"', self.ui)
        self.assertIn('preview.get("hp_after"', self.ui)


if __name__ == "__main__":
    unittest.main()
