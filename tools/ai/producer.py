#!/usr/bin/env python3
"""ProjectTactic AI producer coordinator.

This tool turns structured evidence into a deterministic development report and
bounded proposal packets. It deliberately does not edit gameplay, call a model,
or mutate GitHub. A reasoning or coding agent can consume its output later.
"""

from __future__ import annotations

import argparse
import json
import sys
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SCORECARD = ROOT / "ai" / "evals" / "projecttactic-scorecard.json"
DEFAULT_LESSONS = ROOT / "ai" / "memory" / "lessons.jsonl"

VALID_SOURCES = {
    "ci",
    "godot_test",
    "self_play",
    "browser",
    "performance",
    "human_playtest",
    "static_analysis",
}
VALID_STATUSES = {"pass", "fail", "unknown"}
VALID_SEVERITIES = {"info", "low", "medium", "high", "critical"}
SEVERITY_ORDER = {"critical": 5, "high": 4, "medium": 3, "low": 2, "info": 1}
SEVERITY_PENALTY = {"critical": 45, "high": 28, "medium": 14, "low": 6, "info": 0}
CHECK_PENALTY = {"fail": 30, "unknown": 7, "pass": 0}


class ProducerError(RuntimeError):
    pass


@dataclass(frozen=True)
class Dimension:
    id: str
    label: str
    weight: int
    goal: str
    signals: tuple[str, ...]


def load_json(path: Path) -> dict[str, Any]:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise ProducerError(f"Missing JSON file: {path}") from exc
    except json.JSONDecodeError as exc:
        raise ProducerError(f"Invalid JSON in {path}: {exc}") from exc


def load_lessons(path: Path) -> list[dict[str, Any]]:
    if not path.exists():
        raise ProducerError(f"Missing lessons file: {path}")

    lessons: list[dict[str, Any]] = []
    seen: set[str] = set()
    for line_number, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        line = raw.strip()
        if not line:
            continue
        try:
            item = json.loads(line)
        except json.JSONDecodeError as exc:
            raise ProducerError(f"Invalid JSONL at {path}:{line_number}: {exc}") from exc
        lesson_id = str(item.get("id", "")).strip()
        if not lesson_id:
            raise ProducerError(f"Lesson at {path}:{line_number} is missing id")
        if lesson_id in seen:
            raise ProducerError(f"Duplicate lesson id: {lesson_id}")
        if item.get("status") not in {"accepted", "candidate", "rejected"}:
            raise ProducerError(f"Lesson {lesson_id} has invalid status")
        if not str(item.get("lesson", "")).strip():
            raise ProducerError(f"Lesson {lesson_id} is missing lesson text")
        seen.add(lesson_id)
        lessons.append(item)
    return lessons


def parse_scorecard(path: Path) -> tuple[dict[str, Any], list[Dimension]]:
    raw = load_json(path)
    if raw.get("schema_version") != 1:
        raise ProducerError("Unsupported scorecard schema_version")
    raw_dimensions = raw.get("dimensions")
    if not isinstance(raw_dimensions, list) or not raw_dimensions:
        raise ProducerError("Scorecard must define at least one dimension")

    dimensions: list[Dimension] = []
    seen: set[str] = set()
    total_weight = 0
    for item in raw_dimensions:
        dimension_id = str(item.get("id", "")).strip()
        if not dimension_id or dimension_id in seen:
            raise ProducerError(f"Invalid or duplicate dimension id: {dimension_id!r}")
        weight = int(item.get("weight", 0))
        if weight <= 0:
            raise ProducerError(f"Dimension {dimension_id} must have positive weight")
        label = str(item.get("label", dimension_id)).strip()
        goal = str(item.get("goal", "")).strip()
        signals = item.get("signals", [])
        if not isinstance(signals, list):
            raise ProducerError(f"Dimension {dimension_id} signals must be a list")
        dimensions.append(
            Dimension(
                id=dimension_id,
                label=label,
                weight=weight,
                goal=goal,
                signals=tuple(str(signal) for signal in signals),
            )
        )
        seen.add(dimension_id)
        total_weight += weight

    if total_weight != 100:
        raise ProducerError(f"Scorecard weights must total 100, found {total_weight}")
    return raw, dimensions


def validate_evidence(item: dict[str, Any], dimension_ids: set[str], path: Path) -> None:
    required = {
        "schema_version",
        "evidence_id",
        "build_sha",
        "source",
        "scenario_id",
        "checks",
        "observations",
    }
    missing = sorted(required - item.keys())
    if missing:
        raise ProducerError(f"Evidence {path} missing required fields: {', '.join(missing)}")
    if item.get("schema_version") != 1:
        raise ProducerError(f"Evidence {path} has unsupported schema_version")
    if item.get("source") not in VALID_SOURCES:
        raise ProducerError(f"Evidence {path} has invalid source: {item.get('source')!r}")
    if not str(item.get("evidence_id", "")).strip():
        raise ProducerError(f"Evidence {path} has empty evidence_id")
    if len(str(item.get("build_sha", ""))) < 7:
        raise ProducerError(f"Evidence {path} has invalid build_sha")
    if not str(item.get("scenario_id", "")).strip():
        raise ProducerError(f"Evidence {path} has empty scenario_id")

    checks = item.get("checks")
    observations = item.get("observations")
    if not isinstance(checks, list) or not isinstance(observations, list):
        raise ProducerError(f"Evidence {path} checks and observations must be lists")

    for index, check in enumerate(checks):
        if check.get("status") not in VALID_STATUSES:
            raise ProducerError(f"Evidence {path} check {index} has invalid status")
        dimension = check.get("dimension")
        if dimension is not None and dimension not in dimension_ids:
            raise ProducerError(f"Evidence {path} check {index} references unknown dimension {dimension!r}")
        if not str(check.get("name", "")).strip():
            raise ProducerError(f"Evidence {path} check {index} has empty name")

    seen_observations: set[str] = set()
    for index, observation in enumerate(observations):
        observation_id = str(observation.get("id", "")).strip()
        if not observation_id or observation_id in seen_observations:
            raise ProducerError(f"Evidence {path} observation {index} has invalid or duplicate id")
        seen_observations.add(observation_id)
        if observation.get("severity") not in VALID_SEVERITIES:
            raise ProducerError(f"Evidence {path} observation {observation_id} has invalid severity")
        dimension = observation.get("dimension")
        if dimension is not None and dimension not in dimension_ids:
            raise ProducerError(
                f"Evidence {path} observation {observation_id} references unknown dimension {dimension!r}"
            )
        if not str(observation.get("summary", "")).strip():
            raise ProducerError(f"Evidence {path} observation {observation_id} has empty summary")


def load_evidence(paths: Iterable[Path], dimension_ids: set[str]) -> list[dict[str, Any]]:
    loaded: list[dict[str, Any]] = []
    seen_ids: set[str] = set()
    for path in paths:
        item = load_json(path)
        validate_evidence(item, dimension_ids, path)
        evidence_id = item["evidence_id"]
        if evidence_id in seen_ids:
            raise ProducerError(f"Duplicate evidence_id across inputs: {evidence_id}")
        seen_ids.add(evidence_id)
        item["_path"] = str(path)
        loaded.append(item)
    if not loaded:
        raise ProducerError("At least one evidence file is required")
    return loaded


def health_by_dimension(
    evidence: list[dict[str, Any]], dimensions: list[Dimension]
) -> tuple[dict[str, int], dict[str, int]]:
    penalties: dict[str, int] = defaultdict(int)
    evidence_counts: dict[str, int] = defaultdict(int)
    fallback = "discovery_coverage" if any(d.id == "discovery_coverage" for d in dimensions) else dimensions[0].id

    for item in evidence:
        for check in item["checks"]:
            dimension = check.get("dimension") or fallback
            penalties[dimension] += CHECK_PENALTY[check["status"]]
            evidence_counts[dimension] += 1
        for observation in item["observations"]:
            dimension = observation.get("dimension") or fallback
            penalties[dimension] += SEVERITY_PENALTY[observation["severity"]]
            evidence_counts[dimension] += 1

    health = {dimension.id: max(0, 100 - penalties[dimension.id]) for dimension in dimensions}
    return health, dict(evidence_counts)


def make_failure_proposal(evidence_id: str, check: dict[str, Any]) -> dict[str, Any]:
    name = check["name"]
    dimension = check.get("dimension") or "discovery_coverage"
    return {
        "priority": "blocker",
        "dimension": dimension,
        "observation": f"{evidence_id}: check '{name}' failed",
        "hypothesis": check.get("details") or f"A regression or incomplete implementation causes '{name}' to fail.",
        "change": f"Reproduce '{name}' and make the smallest change that restores the expected behavior.",
        "success_metric": f"The exact '{name}' check passes on the same scenario and build validation path.",
        "guardrail_metric": "No previously passing correctness check becomes failing or unknown.",
        "validation": "Re-run the triggering check plus the nearest related Godot regression suite.",
        "rollback": "Revert the bounded implementation branch if the triggering check or guardrails regress.",
        "source_ids": [evidence_id],
    }


def make_observation_proposal(evidence_id: str, observation: dict[str, Any]) -> dict[str, Any]:
    severity = observation["severity"]
    priority = "blocker" if severity == "critical" else "high" if severity == "high" else "normal"
    dimension = observation.get("dimension") or "discovery_coverage"
    hypothesis = observation.get("hypothesis") or "The observed behavior may represent a reproducible product or system weakness."
    return {
        "priority": priority,
        "dimension": dimension,
        "observation": f"{observation['id']}: {observation['summary']}",
        "hypothesis": hypothesis,
        "change": "Design the smallest experiment that can confirm or falsify the hypothesis before broad implementation.",
        "success_metric": f"The experiment materially improves or resolves observation '{observation['id']}' on repeated evidence.",
        "guardrail_metric": "Correctness, save compatibility, browser delivery, and unrelated tactical behavior do not regress.",
        "validation": "Repeat the triggering scenario, add a regression check when practical, and require human review for player-facing feel.",
        "rollback": "Keep the experiment behind a data or development switch when practical, otherwise revert the branch.",
        "source_ids": [evidence_id],
    }


def make_coverage_proposal(dimension: Dimension) -> dict[str, Any]:
    return {
        "priority": "discovery",
        "dimension": dimension.id,
        "observation": f"No structured evidence currently exercises '{dimension.label}'.",
        "hypothesis": "An important blind spot may exist because this dimension is not represented in the supplied evidence.",
        "change": f"Add one low-cost evidence producer or deterministic scenario for '{dimension.label}'.",
        "success_metric": f"At least one repeatable evidence item reports a signal for '{dimension.id}'.",
        "guardrail_metric": "The new evidence path is deterministic where possible and does not change gameplay behavior.",
        "validation": "Run the evidence producer twice and confirm stable schema output for the same deterministic input.",
        "rollback": "Remove the evidence-only change if it is noisy, flaky, or too expensive to maintain.",
        "source_ids": [],
    }


def build_proposals(evidence: list[dict[str, Any]], dimensions: list[Dimension], counts: dict[str, int]) -> list[dict[str, Any]]:
    proposals: list[dict[str, Any]] = []
    critical_exists = False

    for item in evidence:
        evidence_id = item["evidence_id"]
        for check in item["checks"]:
            if check["status"] == "fail":
                critical_exists = True
                proposals.append(make_failure_proposal(evidence_id, check))
        for observation in item["observations"]:
            if observation["severity"] in {"critical", "high", "medium"}:
                if observation["severity"] == "critical":
                    critical_exists = True
                proposals.append(make_observation_proposal(evidence_id, observation))

    if not critical_exists:
        missing = [dimension for dimension in dimensions if counts.get(dimension.id, 0) == 0]
        missing.sort(key=lambda dimension: dimension.weight, reverse=True)
        proposals.extend(make_coverage_proposal(dimension) for dimension in missing[:3])

    priority_order = {"blocker": 0, "high": 1, "normal": 2, "discovery": 3}
    weight_by_dimension = {dimension.id: dimension.weight for dimension in dimensions}
    proposals.sort(key=lambda p: (priority_order[p["priority"]], -weight_by_dimension.get(p["dimension"], 0)))
    return proposals


def candidate_lessons(evidence: list[dict[str, Any]]) -> list[dict[str, Any]]:
    candidates: list[dict[str, Any]] = []
    index = 1
    for item in evidence:
        for check in item["checks"]:
            if check["status"] != "fail":
                continue
            candidates.append(
                {
                    "id": f"candidate-{index:03d}",
                    "status": "candidate",
                    "lesson": f"Investigate whether failures of '{check['name']}' represent a reusable regression rule before accepting this lesson.",
                    "tags": ["candidate", check.get("dimension") or "discovery_coverage"],
                    "source": item["evidence_id"],
                }
            )
            index += 1
        for observation in item["observations"]:
            if observation["severity"] not in {"critical", "high"}:
                continue
            candidates.append(
                {
                    "id": f"candidate-{index:03d}",
                    "status": "candidate",
                    "lesson": f"Validate whether this finding generalizes before accepting it: {observation['summary']}",
                    "tags": ["candidate", observation.get("dimension") or observation.get("kind", "unknown")],
                    "source": item["evidence_id"],
                }
            )
            index += 1
    return candidates


def render_markdown(
    evidence: list[dict[str, Any]],
    dimensions: list[Dimension],
    health: dict[str, int],
    counts: dict[str, int],
    proposals: list[dict[str, Any]],
    accepted_lessons: list[dict[str, Any]],
) -> str:
    weighted_health = round(sum(health[d.id] * d.weight for d in dimensions) / 100, 1)
    covered_weight = sum(d.weight for d in dimensions if counts.get(d.id, 0) > 0)
    failed_checks = sum(1 for item in evidence for check in item["checks"] if check["status"] == "fail")
    unknown_checks = sum(1 for item in evidence for check in item["checks"] if check["status"] == "unknown")

    lines = [
        "# ProjectTactic AI Producer Report",
        "",
        f"Evidence items: **{len(evidence)}**",
        f"Directional weighted health: **{weighted_health}/100**",
        f"Evidence coverage weight: **{covered_weight}/100**",
        f"Failed checks: **{failed_checks}**",
        f"Unknown checks: **{unknown_checks}**",
        "",
        "> Health is a triage signal, not a fun score. It should never be optimized in isolation.",
        "",
        "## Dimension health",
        "",
        "| Dimension | Weight | Health | Evidence signals |",
        "| --- | ---: | ---: | ---: |",
    ]
    for dimension in dimensions:
        lines.append(
            f"| {dimension.label} | {dimension.weight} | {health[dimension.id]} | {counts.get(dimension.id, 0)} |"
        )

    lines.extend(["", "## Recommended proposals", ""])
    if not proposals:
        lines.append("No proposal was generated from the supplied evidence.")
    for index, proposal in enumerate(proposals, start=1):
        lines.extend(
            [
                f"### {index}. [{proposal['priority'].upper()}] {proposal['dimension']}",
                "",
                f"- Observation: {proposal['observation']}",
                f"- Hypothesis: {proposal['hypothesis']}",
                f"- Smallest change: {proposal['change']}",
                f"- Success metric: {proposal['success_metric']}",
                f"- Guardrail: {proposal['guardrail_metric']}",
                f"- Validation: {proposal['validation']}",
                f"- Rollback: {proposal['rollback']}",
                "",
            ]
        )

    lines.extend(["## Accepted project lessons loaded", ""])
    for lesson in accepted_lessons:
        lines.append(f"- `{lesson['id']}`: {lesson['lesson']}")
    if not accepted_lessons:
        lines.append("- None")
    lines.append("")
    return "\n".join(lines)


def write_analysis(
    output_dir: Path,
    evidence: list[dict[str, Any]],
    dimensions: list[Dimension],
    lessons: list[dict[str, Any]],
) -> None:
    health, counts = health_by_dimension(evidence, dimensions)
    proposals = build_proposals(evidence, dimensions, counts)
    accepted_lessons = [lesson for lesson in lessons if lesson.get("status") == "accepted"]
    candidates = candidate_lessons(evidence)

    output_dir.mkdir(parents=True, exist_ok=True)
    (output_dir / "producer-report.md").write_text(
        render_markdown(evidence, dimensions, health, counts, proposals, accepted_lessons),
        encoding="utf-8",
    )
    (output_dir / "proposals.json").write_text(
        json.dumps({"schema_version": 1, "proposals": proposals}, indent=2) + "\n",
        encoding="utf-8",
    )
    (output_dir / "candidate-lessons.json").write_text(
        json.dumps({"schema_version": 1, "lessons": candidates}, indent=2) + "\n",
        encoding="utf-8",
    )
    context = {
        "schema_version": 1,
        "accepted_lessons": accepted_lessons,
        "dimension_health": health,
        "evidence_counts": counts,
        "proposals": proposals,
    }
    (output_dir / "agent-context.json").write_text(json.dumps(context, indent=2) + "\n", encoding="utf-8")

    print(f"Wrote AI producer report to {output_dir}")
    if proposals:
        print(f"Generated {len(proposals)} bounded proposal(s); top priority: {proposals[0]['priority']}")
    else:
        print("Generated no proposals")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="ProjectTactic AI producer coordinator")
    parser.add_argument("--scorecard", type=Path, default=DEFAULT_SCORECARD)
    parser.add_argument("--lessons", type=Path, default=DEFAULT_LESSONS)
    subparsers = parser.add_subparsers(dest="command", required=True)

    validate = subparsers.add_parser("validate", help="Validate scorecard, lessons, and optional evidence")
    validate.add_argument("--evidence", type=Path, nargs="*")

    analyze = subparsers.add_parser("analyze", help="Analyze evidence and emit proposal packets")
    analyze.add_argument("--evidence", type=Path, nargs="+", required=True)
    analyze.add_argument("--output-dir", type=Path, default=ROOT / ".ai-reports" / "latest")
    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        _, dimensions = parse_scorecard(args.scorecard)
        lessons = load_lessons(args.lessons)
        dimension_ids = {dimension.id for dimension in dimensions}

        if args.command == "validate":
            if args.evidence:
                load_evidence(args.evidence, dimension_ids)
            print(
                f"AI producer configuration valid: {len(dimensions)} dimensions, "
                f"{len(lessons)} lessons, {len(args.evidence or [])} evidence file(s)"
            )
            return 0

        evidence = load_evidence(args.evidence, dimension_ids)
        write_analysis(args.output_dir, evidence, dimensions, lessons)
        return 0
    except ProducerError as exc:
        print(f"AI producer validation failed: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
