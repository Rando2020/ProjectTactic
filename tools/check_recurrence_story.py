#!/usr/bin/env python3
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
manifest_path = ROOT / "godot" / "data" / "story" / "recurrence_manifest.json"
data = json.loads(manifest_path.read_text(encoding="utf-8"))

leaves = data.get("leaves", [])
pairs = data.get("bifurcations", [])
assert len(leaves) == 10, f"expected 10 Leaves, found {len(leaves)}"
assert len(pairs) == 5, f"expected 5 bifurcations, found {len(pairs)}"

ids = [leaf["id"] for leaf in leaves]
assert len(ids) == len(set(ids)), "Leaf ids must be unique"
orders = [leaf["order"] for leaf in leaves]
assert orders == list(range(1, 11)), f"Leaf order must be 1..10, got {orders}"

pair_ids = {pair["id"] for pair in pairs}
for leaf in leaves:
    assert leaf["pair"] in pair_ids, f"{leaf['id']} references unknown pair {leaf['pair']}"

required = [
    ROOT / "godot" / "scripts" / "story" / "RecurrenceStory.gd",
    ROOT / "godot" / "scripts" / "story" / "GuideDialogue.gd",
    ROOT / "docs" / "lore" / "recurrence-narrative-bible.md",
    ROOT / "docs" / "design" / "recurrence-run-integration.md",
]
for path in required:
    assert path.exists(), f"missing recurrence story file: {path.relative_to(ROOT)}"

print("recurrence story contract: OK")
