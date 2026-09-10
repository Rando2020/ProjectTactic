#!/usr/bin/env python3
"""Run ProjectTactic baseline self-play against the real Ashvale battle scene."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
GODOT_DIR = ROOT / "godot"
DEFAULT_ARTIFACT_DIR = ROOT / ".ai-reports" / "self-play-baselines"
KNOWN_GODOT_SHUTDOWN_RESOURCE_ERROR = re.compile(
    r"ERROR: \d+ resources still in use at exit \(run with --verbose for details\)\."
)
SUCCESSFUL_REAL_BATTLE_SENTINEL = re.compile(
    r"Real self-play baseline tests: \d+ pass, 0 fail"
)

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--godot", default="godot")
parser.add_argument("--artifact-dir", type=Path, default=DEFAULT_ARTIFACT_DIR)
args = parser.parse_args()


def run(
    command: list[str],
    *,
    env: dict[str, str],
    timeout: int,
    label: str,
    allow_godot_shutdown_resource_error: bool = False,
) -> str:
    result = subprocess.run(
        command,
        cwd=ROOT,
        env=env,
        capture_output=True,
        text=True,
        timeout=timeout,
    )
    output = result.stdout + result.stderr
    print(output)

    # Godot 4.6.2 can report project-scene resources still referenced during
    # process shutdown even after the runner has synchronously freed its battle,
    # quiesced self-play coroutines, passed every assertion, and returned 0.
    # Allow only that exact shutdown diagnostic, only for successful real-battle
    # processes. Every other ERROR line and every SCRIPT ERROR remains fatal.
    successful_real_battle = (
        allow_godot_shutdown_resource_error
        and result.returncode == 0
        and SUCCESSFUL_REAL_BATTLE_SENTINEL.search(output) is not None
        and "SELF_PLAY_RESULT " in output
    )
    unexpected_error_lines: list[str] = []
    for line in output.splitlines():
        stripped = line.strip()
        if not stripped.startswith("ERROR:"):
            continue
        if successful_real_battle and KNOWN_GODOT_SHUTDOWN_RESOURCE_ERROR.fullmatch(stripped):
            continue
        unexpected_error_lines.append(stripped)

    if result.returncode or "SCRIPT ERROR:" in output or unexpected_error_lines:
        if unexpected_error_lines:
            print("Unexpected Godot error lines:")
            for error_line in unexpected_error_lines:
                print(f"  {error_line}")
        raise SystemExit(f"{label} failed with exit code {result.returncode}")
    return output


def run_mode(mode: str, xdg_dir: Path) -> Path:
    env = dict(os.environ, XDG_DATA_HOME=str(xdg_dir))
    if mode == "policy":
        command = [
            args.godot,
            "--headless",
            "--path",
            str(GODOT_DIR),
            "--script",
            "tests/test_self_play_baselines.gd",
            "--",
            mode,
        ]
    else:
        # Real battles must run as a normal project scene so project autoloads are
        # initialized exactly as they are during gameplay. The standalone policy
        # regression intentionally remains script-based because it has no runtime
        # dependency on BattleManager or the autoload graph.
        command = [
            args.godot,
            "--headless",
            "--path",
            str(GODOT_DIR),
            "tests/SelfPlayBaselineRunner.tscn",
            "--",
            mode,
        ]
    run(
        command,
        env=env,
        timeout=90,
        label=f"Self-play mode {mode}",
        allow_godot_shutdown_resource_error=mode != "policy",
    )
    if mode == "policy":
        return Path()
    matches = list(xdg_dir.rglob(f"ai-self-play/{mode}.json"))
    if len(matches) != 1:
        raise SystemExit(f"Expected exactly one {mode} evidence file, found {len(matches)}")
    return matches[0]


def deterministic_payload(evidence: dict) -> dict:
    """Return only fields that should be identical for a repeated seeded run."""
    return {
        "source": evidence.get("source"),
        "scenario_id": evidence.get("scenario_id"),
        "seed": evidence.get("seed"),
        "metrics": evidence.get("metrics"),
        "checks": evidence.get("checks"),
        "observations": evidence.get("observations"),
        "policy_id": evidence.get("context", {}).get("policy_id"),
        "initial_state": evidence.get("context", {}).get("initial_state"),
        "final_state": evidence.get("context", {}).get("final_state"),
        "events": evidence.get("context", {}).get("events"),
    }


if not sys.platform.startswith("linux"):
    raise SystemExit("Run the isolated self-play checker on Linux/WSL or in CI.")

with tempfile.TemporaryDirectory(prefix="projecttactic-selfplay-") as temp:
    temp_root = Path(temp)
    import_env = dict(os.environ, XDG_DATA_HOME=str(temp_root / "import"))
    run(
        [args.godot, "--headless", "--path", str(GODOT_DIR), "--editor", "--import"],
        env=import_env,
        timeout=600,
        label="Godot import",
    )
    print("Godot import passed.")

    run_mode("policy", temp_root / "policy")
    greedy_path = run_mode("greedy", temp_root / "greedy")
    random_path = run_mode("random", temp_root / "random")
    greedy_repeat_path = run_mode("greedy", temp_root / "greedy-repeat")

    greedy = json.loads(greedy_path.read_text(encoding="utf-8"))
    greedy_repeat = json.loads(greedy_repeat_path.read_text(encoding="utf-8"))
    random_evidence = json.loads(random_path.read_text(encoding="utf-8"))

    if deterministic_payload(greedy) != deterministic_payload(greedy_repeat):
        raise SystemExit("Greedy self-play trajectory changed across identical seeded runs")
    if greedy.get("metrics", {}).get("outcome") not in {"victory", "defeat"}:
        raise SystemExit("Greedy baseline did not complete the real Ashvale battle")
    if int(greedy.get("metrics", {}).get("decision_count", 0)) <= 0:
        raise SystemExit("Greedy baseline emitted no policy decisions")
    if int(random_evidence.get("metrics", {}).get("decision_count", 0)) <= 0:
        raise SystemExit("Random-legal baseline emitted no policy decisions")

    args.artifact_dir.mkdir(parents=True, exist_ok=True)
    greedy_copy = args.artifact_dir / "greedy.json"
    random_copy = args.artifact_dir / "random.json"
    shutil.copyfile(greedy_path, greedy_copy)
    shutil.copyfile(random_path, random_copy)

    producer_env = dict(os.environ)
    run(
        [
            sys.executable,
            "tools/ai/producer.py",
            "validate",
            "--evidence",
            str(greedy_copy),
            str(random_copy),
        ],
        env=producer_env,
        timeout=60,
        label="AI producer self-play validation",
    )
    run(
        [
            sys.executable,
            "tools/ai/producer.py",
            "analyze",
            "--evidence",
            str(greedy_copy),
            str(random_copy),
            "--output-dir",
            str(args.artifact_dir / "producer"),
        ],
        env=producer_env,
        timeout=60,
        label="AI producer self-play analysis",
    )

    summary = {
        "schema_version": 1,
        "scenario_id": "ashvale-debug-map",
        "greedy": {
            "outcome": greedy.get("metrics", {}).get("outcome"),
            "player_turns": greedy.get("metrics", {}).get("turn_count_player"),
            "decisions": greedy.get("metrics", {}).get("decision_count"),
            "hp_lost_player_team": greedy.get("metrics", {}).get("hp_lost_player_team"),
            "deterministic_repeat": True,
        },
        "random": {
            "outcome": random_evidence.get("metrics", {}).get("outcome"),
            "player_turns": random_evidence.get("metrics", {}).get("turn_count_player"),
            "decisions": random_evidence.get("metrics", {}).get("decision_count"),
            "hp_lost_player_team": random_evidence.get("metrics", {}).get("hp_lost_player_team"),
        },
    }
    (args.artifact_dir / "baseline-summary.json").write_text(
        json.dumps(summary, indent=2) + "\n",
        encoding="utf-8",
    )

print(f"Self-play baselines passed. Evidence and producer report: {args.artifact_dir}")
