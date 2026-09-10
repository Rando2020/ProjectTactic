#!/usr/bin/env python3
"""Run deterministic ProjectTactic policies across multiple real tactical scenarios."""

from __future__ import annotations

import argparse
import json
import os
from collections import Counter
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
GODOT_DIR = ROOT / "godot"
DEFAULT_ARTIFACT_DIR = ROOT / ".ai-reports" / "tactical-scenario-matrix"
SCENARIOS = ["ashvale-control", "crypt-control", "generated-floor-4"]
MODES = ["greedy", "random", "ability"]
KNOWN_GODOT_SHUTDOWN_RESOURCE_ERROR = re.compile(
    r"ERROR: \d+ resources still in use at exit \(run with --verbose for details\)\."
)
SUCCESS_SENTINEL = re.compile(r"Real self-play baseline tests: \d+ pass, 0 fail")

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--godot", default="godot")
parser.add_argument("--artifact-dir", type=Path, default=DEFAULT_ARTIFACT_DIR)
args = parser.parse_args()


def run(command: list[str], *, env: dict[str, str], timeout: int, label: str, real_battle: bool = False) -> str:
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
    successful_real_battle = (
        real_battle
        and result.returncode == 0
        and SUCCESS_SENTINEL.search(output) is not None
        and "SELF_PLAY_RESULT " in output
    )
    unexpected_errors: list[str] = []
    for line in output.splitlines():
        stripped = line.strip()
        if not stripped.startswith("ERROR:"):
            continue
        if successful_real_battle and KNOWN_GODOT_SHUTDOWN_RESOURCE_ERROR.fullmatch(stripped):
            continue
        unexpected_errors.append(stripped)
    if result.returncode or "SCRIPT ERROR:" in output or unexpected_errors:
        if unexpected_errors:
            print("Unexpected Godot error lines:")
            for error_line in unexpected_errors:
                print(f"  {error_line}")
        raise SystemExit(f"{label} failed with exit code {result.returncode}")
    return output


def run_scenario(mode: str, scenario_id: str, xdg_dir: Path) -> Path:
    env = dict(os.environ, XDG_DATA_HOME=str(xdg_dir))
    run(
        [
            args.godot,
            "--headless",
            "--path",
            str(GODOT_DIR),
            "tests/SelfPlayBaselineRunner.tscn",
            "--",
            mode,
            scenario_id,
        ],
        env=env,
        timeout=90,
        label=f"Scenario {scenario_id} / {mode}",
        real_battle=True,
    )
    matches = list(xdg_dir.rglob(f"ai-self-play/{scenario_id}/{mode}.json"))
    if len(matches) != 1:
        raise SystemExit(
            f"Expected exactly one evidence file for {scenario_id}/{mode}, found {len(matches)}"
        )
    return matches[0]


def deterministic_payload(evidence: dict[str, Any]) -> dict[str, Any]:
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


def action_counts(evidence: dict[str, Any]) -> dict[str, int]:
    counts: Counter[str] = Counter()
    for event in evidence.get("context", {}).get("events", []):
        if not isinstance(event, dict) or event.get("type") != "decision":
            continue
        payload = event.get("payload", {})
        if isinstance(payload, dict):
            action_id = str(payload.get("action_id", ""))
            if action_id:
                counts[action_id] += 1
    return dict(sorted(counts.items()))


def metric_signature(evidence: dict[str, Any]) -> tuple[Any, ...]:
    metrics = evidence.get("metrics", {})
    return (
        metrics.get("outcome"),
        metrics.get("turn_count_player"),
        metrics.get("decision_count"),
        metrics.get("hp_lost_player_team"),
        metrics.get("hp_lost_enemy_team"),
        metrics.get("defeated_player_units"),
    )


if not sys.platform.startswith("linux"):
    raise SystemExit("Run the tactical scenario matrix on Linux/WSL or in CI.")

args.artifact_dir.mkdir(parents=True, exist_ok=True)

with tempfile.TemporaryDirectory(prefix="projecttactic-scenario-matrix-") as temp:
    temp_root = Path(temp)
    import_env = dict(os.environ, XDG_DATA_HOME=str(temp_root / "import"))
    run(
        [args.godot, "--headless", "--path", str(GODOT_DIR), "--editor", "--import"],
        env=import_env,
        timeout=600,
        label="Godot import",
    )
    print("Godot import passed for tactical scenario matrix.")

    evidence_items: list[dict[str, Any]] = []
    evidence_paths: list[Path] = []
    summary_rows: list[dict[str, Any]] = []

    for scenario_id in SCENARIOS:
        for mode in MODES:
            first_path = run_scenario(mode, scenario_id, temp_root / f"{scenario_id}-{mode}-a")
            repeat_path = run_scenario(mode, scenario_id, temp_root / f"{scenario_id}-{mode}-b")
            first = json.loads(first_path.read_text(encoding="utf-8"))
            repeat = json.loads(repeat_path.read_text(encoding="utf-8"))
            if deterministic_payload(first) != deterministic_payload(repeat):
                raise SystemExit(f"Determinism changed for {scenario_id}/{mode}")
            if first.get("scenario_id") != scenario_id:
                raise SystemExit(f"Scenario identity mismatch for {scenario_id}/{mode}")
            if int(first.get("metrics", {}).get("decision_count", 0)) <= 0:
                raise SystemExit(f"No policy decisions recorded for {scenario_id}/{mode}")

            copy_path = args.artifact_dir / f"{scenario_id}-{mode}.json"
            shutil.copyfile(first_path, copy_path)
            evidence_paths.append(copy_path)
            evidence_items.append(first)
            metrics = first.get("metrics", {})
            summary_rows.append({
                "scenario_id": scenario_id,
                "policy_id": first.get("context", {}).get("policy_id"),
                "outcome": metrics.get("outcome"),
                "player_turns": metrics.get("turn_count_player"),
                "decisions": metrics.get("decision_count"),
                "hp_lost_player_team": metrics.get("hp_lost_player_team"),
                "hp_lost_enemy_team": metrics.get("hp_lost_enemy_team"),
                "defeated_player_units": metrics.get("defeated_player_units"),
                "action_counts": action_counts(first),
                "deterministic_repeat": True,
            })

    represented_scenarios = {item.get("scenario_id") for item in evidence_items}
    represented_policies = {item.get("context", {}).get("policy_id") for item in evidence_items}
    if represented_scenarios != set(SCENARIOS):
        raise SystemExit(f"Scenario coverage mismatch: {sorted(represented_scenarios)}")
    if len(represented_policies) != 3:
        raise SystemExit(f"Expected three policy styles, found {sorted(represented_policies)}")

    for policy_id in represented_policies:
        signatures = {
            metric_signature(item)
            for item in evidence_items
            if item.get("context", {}).get("policy_id") == policy_id
        }
        if len(signatures) < 2:
            raise SystemExit(f"Policy {policy_id} did not respond differently to scenario variation")

    run(
        [sys.executable, "tools/ai/producer.py", "validate", "--evidence", *map(str, evidence_paths)],
        env=dict(os.environ),
        timeout=60,
        label="AI producer matrix validation",
    )
    run(
        [
            sys.executable,
            "tools/ai/producer.py",
            "analyze",
            "--evidence",
            *map(str, evidence_paths),
            "--output-dir",
            str(args.artifact_dir / "producer"),
        ],
        env=dict(os.environ),
        timeout=60,
        label="AI producer matrix analysis",
    )
    run(
        [
            sys.executable,
            "tools/ai/game_director.py",
            "--evidence",
            *map(str, evidence_paths),
            "--output-dir",
            str(args.artifact_dir / "director"),
        ],
        env=dict(os.environ),
        timeout=60,
        label="AI Game Director matrix feedback",
    )

    next_experiment = json.loads(
        (args.artifact_dir / "director" / "next-experiment.json").read_text(encoding="utf-8")
    )
    if next_experiment.get("experiment_id") != "exp-terrain-defensive-policies":
        raise SystemExit(
            "Game Director did not advance beyond scenario coverage: "
            f"{next_experiment.get('experiment_id')}"
        )
    if next_experiment.get("branch_name") != "feature/ai-tactical-policy-breadth":
        raise SystemExit("Game Director emitted an unexpected third-cycle branch")

    matrix_summary = {
        "schema_version": 1,
        "scenarios": SCENARIOS,
        "policies": sorted(str(value) for value in represented_policies),
        "runs": summary_rows,
        "next_experiment": {
            "experiment_id": next_experiment.get("experiment_id"),
            "title": next_experiment.get("title"),
            "branch_name": next_experiment.get("branch_name"),
        },
    }
    (args.artifact_dir / "scenario-matrix-summary.json").write_text(
        json.dumps(matrix_summary, indent=2) + "\n",
        encoding="utf-8",
    )

print("Tactical scenario matrix passed.")
print("Game Director advanced to feature/ai-tactical-policy-breadth.")
