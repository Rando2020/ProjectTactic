#!/usr/bin/env python3
"""Run the real self-play baselines, then make the Game Director choose its next prompt."""

from __future__ import annotations

import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
SELF_PLAY_DIR = ROOT / ".ai-reports" / "self-play-baselines"
DIRECTOR_DIR = ROOT / ".ai-reports" / "game-director"


def run(command: list[str], label: str) -> None:
    result = subprocess.run(command, cwd=ROOT, text=True)
    if result.returncode:
        raise SystemExit(f"{label} failed with exit code {result.returncode}")


run([sys.executable, "tools/check_self_play_baselines.py"], "Real self-play baselines")
run([
    sys.executable,
    "tools/ai/game_director.py",
    "--evidence",
    str(SELF_PLAY_DIR / "greedy.json"),
    str(SELF_PLAY_DIR / "random.json"),
    "--output-dir",
    str(DIRECTOR_DIR),
], "AI Game Director")

required = [
    DIRECTOR_DIR / "next-experiment.json",
    DIRECTOR_DIR / "director-state.json",
    DIRECTOR_DIR / "game-director-report.md",
    DIRECTOR_DIR / "next-agent-prompt.md",
]
for path in required:
    if not path.exists() or path.stat().st_size == 0:
        raise SystemExit(f"Missing Game Director output: {path}")

experiment = json.loads((DIRECTOR_DIR / "next-experiment.json").read_text(encoding="utf-8"))
if experiment.get("experiment_id") != "exp-ability-aware-action-surface":
    raise SystemExit(f"Unexpected first self-generated experiment: {experiment.get('experiment_id')}")
if experiment.get("branch_name") != "feature/ai-ability-action-surface":
    raise SystemExit("Game Director did not emit the expected bounded branch name")

prompt = (DIRECTOR_DIR / "next-agent-prompt.md").read_text(encoding="utf-8")
for required_text in [
    "The Appointed",
    "Do not commit directly to main",
    "Do not merge automatically",
    "Human acceptance gate",
    "Feed the new evidence back into the AI Producer and Game Director",
]:
    if required_text not in prompt:
        raise SystemExit(f"Self-generated prompt missing required guardrail: {required_text}")

print("AI Game Director validation passed.")
print(f"Selected next experiment: {experiment['title']}")
print(f"Self-generated next branch: {experiment['branch_name']}")
