#!/usr/bin/env python3
"""Run real self-play, then require the Game Director to advance its own prompt."""

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
    str(SELF_PLAY_DIR / "ability.json"),
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
if experiment.get("experiment_id") != "exp-deterministic-scenario-matrix":
    raise SystemExit(f"Director did not advance after ability evidence: {experiment.get('experiment_id')}")
if experiment.get("branch_name") != "feature/ai-tactical-scenario-matrix":
    raise SystemExit("Game Director did not emit the expected second-cycle branch name")

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

print("AI Game Director feedback-loop validation passed.")
print(f"Selected next experiment: {experiment['title']}")
print(f"Self-generated next branch: {experiment['branch_name']}")
