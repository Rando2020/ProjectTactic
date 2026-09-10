#!/usr/bin/env python3
"""Run isolated BattleTelemetry regression and feed its evidence to the AI producer."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
GODOT_DIR = ROOT / "godot"
DEFAULT_ARTIFACT_DIR = ROOT / ".ai-reports" / "battle-telemetry"

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--godot", default="godot")
parser.add_argument("--artifact-dir", type=Path, default=DEFAULT_ARTIFACT_DIR)
args = parser.parse_args()


def run(command: list[str], *, env: dict[str, str], timeout: int, label: str) -> str:
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
    if result.returncode or "SCRIPT ERROR:" in output or "\nERROR:" in output:
        raise SystemExit(f"{label} failed with exit code {result.returncode}")
    return output


if not sys.platform.startswith("linux"):
    raise SystemExit("Run the isolated BattleTelemetry checker on Linux/WSL or in CI.")

with tempfile.TemporaryDirectory(prefix="projecttactic-telemetry-") as temp:
    isolated = Path(temp)
    env = dict(os.environ, XDG_DATA_HOME=str(isolated))

    run(
        [args.godot, "--headless", "--path", str(GODOT_DIR), "--editor", "--import"],
        env=env,
        timeout=600,
        label="Godot import",
    )
    print("Godot import passed.")

    run(
        [args.godot, "--headless", "--path", str(GODOT_DIR), "--script", "tests/test_battle_telemetry.gd"],
        env=env,
        timeout=120,
        label="Battle telemetry regression",
    )

    matches = list(isolated.rglob("ai-telemetry-test/evidence.json"))
    if len(matches) != 1:
        raise SystemExit(f"Expected exactly one exported telemetry evidence file, found {len(matches)}")
    evidence_path = matches[0]

    evidence = json.loads(evidence_path.read_text(encoding="utf-8"))
    if evidence.get("scenario_id") != "telemetry-smoke":
        raise SystemExit("Telemetry evidence scenario identity changed unexpectedly")
    if evidence.get("metrics", {}).get("outcome") != "victory":
        raise SystemExit("Telemetry evidence did not preserve the fixture outcome")

    args.artifact_dir.mkdir(parents=True, exist_ok=True)
    copied_evidence = args.artifact_dir / "evidence.json"
    shutil.copyfile(evidence_path, copied_evidence)

    run(
        [sys.executable, "tools/ai/producer.py", "validate", "--evidence", str(copied_evidence)],
        env=env,
        timeout=60,
        label="AI producer evidence validation",
    )
    run(
        [
            sys.executable,
            "tools/ai/producer.py",
            "analyze",
            "--evidence",
            str(copied_evidence),
            "--output-dir",
            str(args.artifact_dir / "producer"),
        ],
        env=env,
        timeout=60,
        label="AI producer telemetry analysis",
    )

print(f"BattleTelemetry regression passed. Evidence and producer report: {args.artifact_dir}")
