#!/usr/bin/env python3
"""Build a durable ProjectTactic creative brief for ChatGPT from source-controlled memory.

Stdlib-only. This tool does not call an LLM or modify gameplay. It validates the
creative constitution and memory ledgers, then produces a compact Markdown brief
that can be handed to ChatGPT at the start of a ProjectTactic work session.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
GOALS = ROOT / "ai" / "goals" / "appointed-creative-constitution.json"
MEMORY_FILES = [
    ROOT / "ai" / "memory" / "design-decisions.jsonl",
    ROOT / "ai" / "memory" / "creative-lessons.jsonl",
    ROOT / "ai" / "memory" / "player-feedback.jsonl",
    ROOT / "ai" / "memory" / "story-principles.jsonl",
]


class BriefError(RuntimeError):
    pass


def load_json(path: Path) -> dict[str, Any]:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise BriefError(f"Could not read valid JSON from {path}: {exc}") from exc
    if not isinstance(data, dict):
        raise BriefError(f"Expected object in {path}")
    return data


def load_jsonl(path: Path) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    try:
        raw_lines = path.read_text(encoding="utf-8").splitlines()
    except OSError as exc:
        raise BriefError(f"Could not read {path}: {exc}") from exc
    for line_no, raw in enumerate(raw_lines, start=1):
        if not raw.strip():
            continue
        try:
            item = json.loads(raw)
        except json.JSONDecodeError as exc:
            raise BriefError(f"Invalid JSONL at {path}:{line_no}: {exc}") from exc
        if not isinstance(item, dict):
            raise BriefError(f"Expected object at {path}:{line_no}")
        if item.get("schema_version") != 1:
            raise BriefError(f"Unsupported schema_version at {path}:{line_no}")
        if not str(item.get("memory_id", "")).strip():
            raise BriefError(f"Missing memory_id at {path}:{line_no}")
        if not str(item.get("status", "")).strip():
            raise BriefError(f"Missing status at {path}:{line_no}")
        if not str(item.get("kind", "")).strip():
            raise BriefError(f"Missing kind at {path}:{line_no}")
        if not str(item.get("summary", "")).strip():
            raise BriefError(f"Missing summary at {path}:{line_no}")
        rows.append(item)
    return rows


def validate_constitution(data: dict[str, Any]) -> None:
    if data.get("schema_version") != 1:
        raise BriefError("Creative constitution must use schema_version 1")
    principles = data.get("principles")
    if not isinstance(principles, list) or not principles:
        raise BriefError("Creative constitution must define principles")
    total = 0
    ids: set[str] = set()
    for principle in principles:
        if not isinstance(principle, dict):
            raise BriefError("Each creative principle must be an object")
        pid = str(principle.get("id", "")).strip()
        if not pid or pid in ids:
            raise BriefError(f"Creative principle id missing or duplicated: {pid!r}")
        ids.add(pid)
        weight = principle.get("weight")
        if not isinstance(weight, int) or weight < 0:
            raise BriefError(f"Invalid weight for principle {pid}")
        total += weight
    if total != 100:
        raise BriefError(f"Creative principle weights must total 100, got {total}")


def render(constitution: dict[str, Any], memories: list[dict[str, Any]]) -> str:
    accepted = [m for m in memories if m.get("status") == "accepted"]
    provisional = [m for m in memories if m.get("status") not in {"accepted", "rejected"}]
    rejected = [m for m in memories if m.get("status") == "rejected"]

    lines = [
        "# The Appointed — ChatGPT Creative Brief",
        "",
        "> Generated from source-controlled ProjectTactic creative goals and memory. Do not treat this file as a substitute for current code, tests, PR status, or human direction.",
        "",
        "## North star",
        "",
        str(constitution.get("north_star", "")),
        "",
        "## Creative principles",
        "",
    ]
    for principle in sorted(constitution["principles"], key=lambda item: int(item["weight"]), reverse=True):
        lines.append(f"- **{principle['id']} ({principle['weight']})**: {principle['goal']}")

    lines.extend(["", "## Accepted project memory", ""])
    for memory in accepted:
        lines.append(f"- **{memory['kind']} / {memory['memory_id']}**: {memory['summary']}")

    lines.extend(["", "## Provisional memory", ""])
    if provisional:
        for memory in provisional:
            lines.append(f"- **{memory['kind']} / {memory['memory_id']}**: {memory['summary']}")
    else:
        lines.append("- None recorded.")

    lines.extend(["", "## Rejected directions and lessons", ""])
    if rejected:
        for memory in rejected:
            reason = memory.get("reason", memory.get("impact", ""))
            suffix = f" Reason: {reason}" if reason else ""
            lines.append(f"- **{memory['memory_id']}**: {memory['summary']}.{suffix}")
    else:
        lines.append("- None recorded yet. Record rejections when they teach durable project taste.")

    lines.extend([
        "",
        "## Self-prompt rule",
        "",
        "Ask: **What is the highest-leverage thing The Appointed does not yet know about whether it is becoming a remarkable tactical roguelike, and what is the smallest experiment that can teach us?**",
        "",
        "Before implementing, separate observation from hypothesis. After evaluating, update durable memory only when evidence or human acceptance justifies it.",
        "",
    ])
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", default=".ai-reports/chatgpt/creative-brief.md")
    args = parser.parse_args()

    constitution = load_json(GOALS)
    validate_constitution(constitution)
    memories: list[dict[str, Any]] = []
    seen: set[str] = set()
    for path in MEMORY_FILES:
        for item in load_jsonl(path):
            memory_id = str(item["memory_id"])
            if memory_id in seen:
                raise BriefError(f"Duplicate memory_id across ledgers: {memory_id}")
            seen.add(memory_id)
            memories.append(item)

    output = ROOT / args.out
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(render(constitution, memories), encoding="utf-8")
    print(f"ChatGPT creative brief valid: {len(constitution['principles'])} principles, {len(memories)} memory entries")
    print(f"Wrote {output}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except BriefError as exc:
        print(f"ERROR: {exc}")
        raise SystemExit(1)
