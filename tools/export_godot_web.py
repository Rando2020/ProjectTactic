#!/usr/bin/env python3
"""Import and export the Godot Web preset, rejecting engine errors even on exit 0."""

import argparse
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]


def run_godot(executable, arguments, log_path):
    result = subprocess.run(
        [executable, "--headless", "--path", str(ROOT / "godot"), *arguments],
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True,
        encoding="utf-8", errors="replace", timeout=600,
    )
    log_path.write_text(result.stdout, encoding="utf-8")
    print(result.stdout)
    clean_log = re.sub(r"\x1b\[[0-9;]*m", "", result.stdout)
    if result.returncode or re.search(r"(?m)^\s*(?:SCRIPT ERROR|ERROR):", clean_log):
        raise RuntimeError(f"Godot failed; inspect {log_path}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default="godot", help="Godot 4.6.2 executable")
    args = parser.parse_args()
    output = ROOT / "build" / "web"
    logs = ROOT / "build" / "godot-logs"
    output.mkdir(parents=True, exist_ok=True)
    logs.mkdir(parents=True, exist_ok=True)
    # A checkout without LFS content must fail before importing placeholder pointers.
    for path in (ROOT / "godot").rglob("*"):
        if path.is_file() and ".godot" not in path.parts:
            with path.open("rb") as source:
                if source.read(42).startswith(b"version https://git-lfs.github.com/spec/v1"):
                    raise RuntimeError(f"Missing Git LFS asset: {path.relative_to(ROOT)}")
    run_godot(args.godot, ["--editor", "--import"], logs / "import.log")
    run_godot(args.godot, ["--export-release", "Web", str(output / "index.html")], logs / "export.log")
    for name in ("index.html", "index.js", "index.wasm", "index.pck"):
        path = output / name
        if not path.is_file() or path.stat().st_size == 0:
            raise RuntimeError(f"Missing or empty Web export: {path}")
    (output / ".nojekyll").touch()
    print(f"Web export ready: {output}")


if __name__ == "__main__":
    try:
        main()
    except (OSError, RuntimeError, subprocess.TimeoutExpired) as error:
        print(error, file=sys.stderr)
        sys.exit(1)
