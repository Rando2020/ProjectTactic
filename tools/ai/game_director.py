#!/usr/bin/env python3
"""Choose ProjectTactic's next bounded gameplay experiment and write its agent prompt.

The director is deliberately model-neutral. It converts real evidence plus the game's
stable design north star into a deterministic experiment packet. A coding or reasoning
agent can consume the generated prompt, but this tool never edits gameplay or GitHub.
"""

from __future__ import annotations

import argparse
import json
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_GOALS = ROOT / "ai" / "goals" / "appointed-game-director.json"
DEFAULT_OUTPUT = ROOT / ".ai-reports" / "game-director"


class DirectorError(RuntimeError):
    pass


def load_json(path: Path) -> dict[str, Any]:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise DirectorError(f"Missing JSON file: {path}") from exc
    except json.JSONDecodeError as exc:
        raise DirectorError(f"Invalid JSON in {path}: {exc}") from exc


def validate_goals(goals: dict[str, Any]) -> dict[str, int]:
    if goals.get("schema_version") != 1:
        raise DirectorError("Unsupported game-director goal schema")
    pillars = goals.get("pillars")
    if not isinstance(pillars, list) or not pillars:
        raise DirectorError("Game director requires at least one design pillar")
    weights: dict[str, int] = {}
    total = 0
    for pillar in pillars:
        pillar_id = str(pillar.get("id", "")).strip()
        weight = int(pillar.get("weight", 0))
        if not pillar_id or pillar_id in weights or weight <= 0:
            raise DirectorError(f"Invalid game-director pillar: {pillar_id!r}")
        weights[pillar_id] = weight
        total += weight
    if total != 100:
        raise DirectorError(f"Game-director pillar weights must total 100, found {total}")
    return weights


def load_evidence(paths: list[Path]) -> list[dict[str, Any]]:
    if not paths:
        raise DirectorError("At least one evidence file is required")
    items: list[dict[str, Any]] = []
    seen: set[str] = set()
    for path in paths:
        item = load_json(path)
        evidence_id = str(item.get("evidence_id", "")).strip()
        if item.get("schema_version") != 1 or not evidence_id:
            raise DirectorError(f"Evidence {path} does not use ProjectTactic evidence schema v1")
        if evidence_id in seen:
            raise DirectorError(f"Duplicate evidence_id: {evidence_id}")
        seen.add(evidence_id)
        items.append(item)
    return items


def decision_actions(item: dict[str, Any]) -> list[str]:
    result: list[str] = []
    events = item.get("context", {}).get("events", [])
    if not isinstance(events, list):
        return result
    for event in events:
        if not isinstance(event, dict) or event.get("type") != "decision":
            continue
        payload = event.get("payload", {})
        if isinstance(payload, dict):
            action_id = str(payload.get("action_id", "")).strip()
            if action_id:
                result.append(action_id)
    return result


def summarize(evidence: list[dict[str, Any]]) -> dict[str, Any]:
    self_play = [item for item in evidence if item.get("source") == "self_play"]
    scenarios = sorted({str(item.get("scenario_id", "")) for item in self_play if item.get("scenario_id")})
    policies = sorted({str(item.get("context", {}).get("policy_id", "")) for item in self_play if item.get("context", {}).get("policy_id")})
    actions: Counter[str] = Counter()
    outcomes: Counter[str] = Counter()
    metrics_by_policy: dict[str, list[dict[str, Any]]] = defaultdict(list)
    failed_checks: list[dict[str, str]] = []

    for item in evidence:
        for check in item.get("checks", []):
            if isinstance(check, dict) and check.get("status") == "fail":
                failed_checks.append({
                    "evidence_id": str(item.get("evidence_id", "")),
                    "name": str(check.get("name", "unknown-check")),
                    "details": str(check.get("details", "")),
                })

    for item in self_play:
        actions.update(decision_actions(item))
        metrics = item.get("metrics", {}) if isinstance(item.get("metrics"), dict) else {}
        outcome = str(metrics.get("outcome", "unknown"))
        outcomes[outcome] += 1
        policy = str(item.get("context", {}).get("policy_id", "unknown-policy"))
        metrics_by_policy[policy].append(metrics)

    baseline_action_ids = {"basic-attack", "move", "wait"}
    ability_like_actions = sorted(action for action in actions if action not in baseline_action_ids)
    return {
        "evidence_count": len(evidence),
        "self_play_count": len(self_play),
        "scenarios": scenarios,
        "policies": policies,
        "action_counts": dict(sorted(actions.items())),
        "ability_like_actions": ability_like_actions,
        "outcomes": dict(sorted(outcomes.items())),
        "metrics_by_policy": dict(metrics_by_policy),
        "failed_checks": failed_checks,
    }


def make_blocker(summary: dict[str, Any]) -> dict[str, Any]:
    first = summary["failed_checks"][0]
    return {
        "schema_version": 1,
        "experiment_id": "exp-fix-evidence-blocker",
        "title": f"Restore failing evidence gate: {first['name']}",
        "priority": "blocker",
        "goal_pillars": ["readability_fairness"],
        "observation": f"Structured evidence reports a failed check: {first['name']}.",
        "hypothesis": first["details"] or "A regression is preventing reliable gameplay evaluation.",
        "change": "Reproduce the failure and make the smallest isolated fix before running new gameplay experiments.",
        "success_metrics": [f"The exact check '{first['name']}' passes on the same evidence path."],
        "guardrails": ["No previously passing correctness or deterministic self-play check regresses."],
        "validation": ["Re-run the triggering check.", "Re-run the nearest related Godot regression and self-play baseline."],
        "rollback": "Revert the fix branch if the triggering gate remains failing or an existing guardrail regresses.",
        "branch_name": "fix/ai-evidence-blocker",
        "human_acceptance_questions": ["Does the fix preserve the same intended player-facing behavior?"],
        "source_evidence_ids": [first["evidence_id"]],
        "confidence": 0.95,
        "unknowns": [],
    }


def candidate_ability_surface(summary: dict[str, Any], weights: dict[str, int]) -> tuple[int, dict[str, Any]] | None:
    if summary["self_play_count"] == 0 or summary["ability_like_actions"]:
        return None
    score = weights["meaningful_decisions"] + weights["build_expression"] + weights["tactical_mastery"] + 30
    return score, {
        "schema_version": 1,
        "experiment_id": "exp-ability-aware-action-surface",
        "title": "Expose real abilities to self-play without changing the existing baselines",
        "priority": "high",
        "goal_pillars": ["meaningful_decisions", "build_expression", "tactical_mastery"],
        "observation": "All recorded self-play decisions are limited to basic attack, movement, and wait, so the evaluator cannot measure the abilities and synergies that define the roguelike tactics loop.",
        "hypothesis": "Adding legal ability actions plus a separate ability-aware policy will reveal whether character kits create tactically meaningful alternatives to basic damage without invalidating the existing greedy and random controls.",
        "change": "Extend SelfPlayDecisionSurface with legal single-target, self, and bounded AoE ability actions using the real AbilityDB/BattleManager targeting rules. Add a new ability-aware policy as a separate baseline; do not change greedy-damage-v1 or random-legal-v1 behavior.",
        "success_metrics": [
            "At least one deterministic Ashvale run records an ability action when a legal useful ability is available.",
            "Ability actions include enough normalized features to compare expected damage/healing/status value, MP cost, target count, and positional consequences.",
            "Existing greedy and random seeded trajectories remain unchanged.",
            "The AI producer receives the new evidence and can distinguish basic-action-only versus ability-aware behavior."
        ],
        "guardrails": [
            "No combat formula or production ability behavior is duplicated inside the self-play layer.",
            "No gameplay balance values are changed in this experiment.",
            "Existing deterministic greedy and random baselines remain controls.",
            "All real-battle tests continue to use normal project startup and controller quiescence boundaries.",
            "No automatic merge or direct commit to main."
        ],
        "validation": [
            "Run policy unit tests plus the full real-battle self-play suite on Godot 4.6.2.",
            "Repeat the same ability-aware seed and compare the complete deterministic trajectory.",
            "Validate all evidence through tools/ai/producer.py.",
            "Inspect whether the selected ability was actually legal and useful under the real forecast/targeting rules."
        ],
        "rollback": "Remove the ability-aware adapter/policy while preserving the original telemetry and basic self-play controls if determinism or rule fidelity cannot be maintained.",
        "branch_name": "feature/ai-ability-action-surface",
        "human_acceptance_questions": [
            "Do the abilities the agent values also feel like interesting choices to a human player?",
            "Does ability usage create different tactical lines rather than simply replacing basic attack with a larger number?",
            "Are any legal but confusing actions technically optimal in a way that would make the game less fun?"
        ],
        "source_evidence_ids": [],
        "confidence": 0.93,
        "unknowns": [
            "The current evidence does not yet measure utility for buffs, control, displacement, or delayed status effects.",
            "AoE evaluation needs a bounded target-center enumeration rule to avoid combinatorial explosion."
        ],
    }


def candidate_scenario_matrix(summary: dict[str, Any], weights: dict[str, int]) -> tuple[int, dict[str, Any]] | None:
    if summary["self_play_count"] == 0 or len(summary["scenarios"]) >= 3:
        return None
    score = weights["tactical_mastery"] + weights["replayability_surprise"] + weights["tension_pacing"] + 18
    return score, {
        "schema_version": 1,
        "experiment_id": "exp-deterministic-scenario-matrix",
        "title": "Expand self-play beyond one Ashvale configuration",
        "priority": "high",
        "goal_pillars": ["tactical_mastery", "replayability_surprise", "tension_pacing"],
        "observation": f"Self-play currently covers only {len(summary['scenarios'])} scenario identity, which is insufficient to distinguish map-specific behavior from general tactical behavior.",
        "hypothesis": "A small deterministic scenario matrix will reveal whether policy performance changes with terrain, formation, enemy composition, and objective pressure.",
        "change": "Add 3 to 5 deterministic development scenarios that vary elevation/terrain, starting distance, enemy composition, and objective pressure without adding new content systems.",
        "success_metrics": ["Each scenario produces repeatable evidence for the same seed.", "Policy performance deltas vary meaningfully across at least one scenario dimension."],
        "guardrails": ["Scenario fixtures do not alter production map generation or campaign data.", "Existing Ashvale baselines remain unchanged."],
        "validation": ["Run greedy and random controls across every scenario twice.", "Aggregate outcomes, turns, HP pressure, and action distributions by scenario."],
        "rollback": "Remove any scenario fixture that is flaky, redundant, or coupled to presentation-only behavior.",
        "branch_name": "feature/ai-tactical-scenario-matrix",
        "human_acceptance_questions": ["Do these fixtures represent tactical situations we actually want The Appointed to reward?"],
        "source_evidence_ids": [],
        "confidence": 0.88,
        "unknowns": ["One debug battle cannot estimate full run difficulty or replayability."],
    }


def candidate_policy_breadth(summary: dict[str, Any], weights: dict[str, int]) -> tuple[int, dict[str, Any]] | None:
    if summary["self_play_count"] == 0 or len(summary["policies"]) >= 4:
        return None
    score = weights["meaningful_decisions"] + weights["tactical_mastery"] + 12
    return score, {
        "schema_version": 1,
        "experiment_id": "exp-terrain-defensive-policies",
        "title": "Add terrain-seeking and defensive-survival controls",
        "priority": "normal",
        "goal_pillars": ["meaningful_decisions", "tactical_mastery"],
        "observation": f"Only {len(summary['policies'])} policy styles are represented, so the evaluator cannot tell whether positioning and survival strategies compete with raw damage.",
        "hypothesis": "Transparent terrain-seeking and defensive policies will expose encounters where positioning or damage prevention has real strategic value.",
        "change": "Add separate deterministic terrain-seeking and defensive-survival policies using the existing normalized action surface.",
        "success_metrics": ["Both policies complete bounded real-battle runs and produce deterministic evidence.", "At least one tactical metric differs from greedy-damage-v1 in an interpretable way."],
        "guardrails": ["Do not alter enemy AI or combat rules.", "Do not tune game balance to make a policy look better."],
        "validation": ["Repeat each seeded policy trajectory.", "Compare turns, HP lost, movement, and positional features to greedy/random."],
        "rollback": "Remove a policy if its heuristic is not interpretable or it duplicates an existing control.",
        "branch_name": "feature/ai-tactical-policy-breadth",
        "human_acceptance_questions": ["Would a skilled human recognize the policy as a coherent tactical style rather than metric gaming?"],
        "source_evidence_ids": [],
        "confidence": 0.82,
        "unknowns": [],
    }


def choose_experiment(summary: dict[str, Any], weights: dict[str, int], evidence: list[dict[str, Any]]) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    if summary["failed_checks"]:
        exp = make_blocker(summary)
        return exp, [{"score": 999, "experiment_id": exp["experiment_id"], "reason": "Correctness/evidence blocker"}]

    candidates: list[tuple[int, dict[str, Any], str]] = []
    for builder, reason in [
        (candidate_ability_surface, "Core roguelike ability/build expression is currently unobservable"),
        (candidate_scenario_matrix, "Only one scenario family is represented"),
        (candidate_policy_breadth, "Too few tactical styles are represented"),
    ]:
        built = builder(summary, weights)
        if built is not None:
            score, experiment = built
            candidates.append((score, experiment, reason))

    if not candidates:
        experiment = {
            "schema_version": 1,
            "experiment_id": "exp-human-playtest-calibration",
            "title": "Calibrate automated fun proxies against human playtests",
            "priority": "discovery",
            "goal_pillars": ["meaningful_decisions", "readability_fairness"],
            "observation": "Automated coverage is broad enough that the next unknown is whether the measured advantages correlate with human fun and clarity.",
            "hypothesis": "A short structured human playtest will reveal which automated metrics best track engaging tactical decisions.",
            "change": "Add a lightweight playtest questionnaire and evidence importer; do not change gameplay in this experiment.",
            "success_metrics": ["Human ratings can be joined to build/scenario evidence without personal data."],
            "guardrails": ["Do not infer fun solely from completion or win rate."],
            "validation": ["Collect at least one structured playtest against a known self-play scenario."],
            "rollback": "Remove questions that do not affect future decisions.",
            "branch_name": "feature/ai-human-playtest-calibration",
            "human_acceptance_questions": ["Which turns felt tense, clever, surprising, obvious, or tedious?"],
            "source_evidence_ids": [],
            "confidence": 0.75,
            "unknowns": [],
        }
        return experiment, [{"score": 1, "experiment_id": experiment["experiment_id"], "reason": "Automated blind spots reduced"}]

    candidates.sort(key=lambda row: (-row[0], row[1]["experiment_id"]))
    chosen = candidates[0][1]
    chosen["source_evidence_ids"] = [str(item.get("evidence_id", "")) for item in evidence]
    ranked = [{"score": score, "experiment_id": exp["experiment_id"], "reason": reason} for score, exp, reason in candidates]
    return chosen, ranked


def render_prompt(goals: dict[str, Any], experiment: dict[str, Any], summary: dict[str, Any]) -> str:
    metrics_lines: list[str] = []
    for policy, rows in sorted(summary["metrics_by_policy"].items()):
        for metrics in rows[:1]:
            metrics_lines.append(
                f"- {policy}: outcome={metrics.get('outcome')}, player_turns={metrics.get('turn_count_player')}, "
                f"decisions={metrics.get('decision_count')}, hp_lost_player_team={metrics.get('hp_lost_player_team')}"
            )
    if not metrics_lines:
        metrics_lines.append("- No self-play metrics supplied.")

    return "\n".join([
        "# ProjectTactic self-generated implementation prompt",
        "",
        "You are the implementation agent for ProjectTactic / The Appointed.",
        "",
        "## North star",
        goals["north_star"],
        "",
        "## Evidence that caused this prompt",
        *metrics_lines,
        f"- Recorded decision actions: {json.dumps(summary['action_counts'], sort_keys=True)}",
        f"- Scenarios represented: {', '.join(summary['scenarios']) or 'none'}",
        "",
        "## Selected experiment",
        f"**{experiment['title']}**",
        "",
        f"Observation: {experiment['observation']}",
        f"Hypothesis: {experiment['hypothesis']}",
        f"Bounded change: {experiment['change']}",
        "",
        "## Required workflow",
        "1. Inspect the current repo and stacked AI PRs before editing.",
        f"2. Create branch `{experiment['branch_name']}` from the current Game Director branch or its merged equivalent.",
        "3. Implement only this experiment. Do not combine unrelated gameplay systems.",
        "4. Preserve existing working behavior and deterministic controls.",
        "5. Add or update system documentation.",
        "6. Run the listed validation plus existing nearby regressions.",
        "7. Open a pull request. Do not commit directly to main. Do not merge automatically.",
        "8. Feed the new evidence back into the AI Producer and Game Director so the next prompt is selected from results, not from assumption.",
        "",
        "## Success metrics",
        *[f"- {metric}" for metric in experiment["success_metrics"]],
        "",
        "## Guardrails",
        *[f"- {guardrail}" for guardrail in experiment["guardrails"]],
        "",
        "## Validation",
        *[f"- {step}" for step in experiment["validation"]],
        "",
        "## Human acceptance gate",
        *[f"- {question}" for question in experiment["human_acceptance_questions"]],
        "",
        f"Rollback: {experiment['rollback']}",
        "",
        "When the PR is ready, report what changed, files added/modified, evidence delta, risks, and the next Game Director prompt. Do not merge.",
        "",
    ])


def render_report(goals: dict[str, Any], experiment: dict[str, Any], summary: dict[str, Any], ranked: list[dict[str, Any]]) -> str:
    lines = [
        "# The Appointed AI Game Director",
        "",
        f"**North star:** {goals['north_star']}",
        "",
        "## Current evidence",
        "",
        f"- Evidence items: {summary['evidence_count']}",
        f"- Self-play items: {summary['self_play_count']}",
        f"- Scenarios represented: {len(summary['scenarios'])}",
        f"- Policies represented: {len(summary['policies'])}",
        f"- Recorded action ids: {json.dumps(summary['action_counts'], sort_keys=True)}",
        "",
        "## Director decision",
        "",
        f"**{experiment['title']}** (`{experiment['experiment_id']}`)",
        "",
        experiment["observation"],
        "",
        f"Hypothesis: {experiment['hypothesis']}",
        "",
        "### Ranked opportunities",
        "",
    ]
    for row in ranked:
        lines.append(f"- {row['score']}: `{row['experiment_id']}` - {row['reason']}")
    lines.extend([
        "",
        "## Self-improvement contract",
        "",
        "The Director improves the development loop by choosing what to test next, not by declaring its own suggestion correct. Every gameplay proposal must return through evidence, regression checks, and human acceptance before it becomes an accepted lesson.",
        "",
        "A generated prompt is an experiment packet, not permission to merge.",
        "",
    ])
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--goals", type=Path, default=DEFAULT_GOALS)
    parser.add_argument("--evidence", type=Path, nargs="+", required=True)
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()

    try:
        goals = load_json(args.goals)
        weights = validate_goals(goals)
        evidence = load_evidence(args.evidence)
        summary = summarize(evidence)
        experiment, ranked = choose_experiment(summary, weights, evidence)
        args.output_dir.mkdir(parents=True, exist_ok=True)
        (args.output_dir / "next-experiment.json").write_text(json.dumps(experiment, indent=2) + "\n", encoding="utf-8")
        (args.output_dir / "director-state.json").write_text(
            json.dumps({"schema_version": 1, "summary": summary, "ranked_opportunities": ranked}, indent=2) + "\n",
            encoding="utf-8",
        )
        (args.output_dir / "game-director-report.md").write_text(render_report(goals, experiment, summary, ranked), encoding="utf-8")
        (args.output_dir / "next-agent-prompt.md").write_text(render_prompt(goals, experiment, summary), encoding="utf-8")
        print(f"Game Director selected: {experiment['experiment_id']}")
        print(f"Next branch: {experiment['branch_name']}")
        print(f"Wrote self-generated prompt to {args.output_dir / 'next-agent-prompt.md'}")
        return 0
    except DirectorError as exc:
        print(f"Game Director failed: {exc}")
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
