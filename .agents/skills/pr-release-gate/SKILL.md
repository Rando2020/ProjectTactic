---
name: pr-release-gate
description: Carry a ProjectTactic change from isolated branch through honest validation and a reviewable pull request, then stop before merging. Inspired by tstack full-stop, file-pr, and babysit-pr.
---
# ProjectTactic PR release gate

Use for implementation and repairs after the approved scope is understood.

1. Inspect current `main`, relevant open PRs, repository rules, and the exact task before editing. Do not duplicate or overwrite existing work.
2. Work only on a topic branch. Never force-push, commit directly to `main`, or change release deployments.
3. Check `CLAUDE.md`: production gameplay is in `godot/`, React is read-only reference.
4. Run the matching existing checks: `tools/check_godot_stability.cmd --skip-godot`, `python tools/check_recurrence_story.py` when lore is affected, and Godot import/export or editor playtests when available. Capture actual commands, environment, output, and limitations; do not report unrun tests as passing.
5. Review new files, binary assets, licenses, dependencies, save compatibility, and asset paths. Compare branch changes with the base.
6. Open a **draft pull request** with problem, scope, evidence, screenshots when UI changes, risk, rollback, and unresolved checks.
7. Check CI and review findings when available. Only address reproducible findings, on the same branch, with proof. An agent must not claim to be waiting or watching asynchronously unless a real monitor has been configured.
8. **Stop at the owner gate. No automatic merge**, release, asset overwrite, or production deployment.

When the external tstack skills are present, use `file-pr` and `babysit-pr` under this repository policy; `full-stop` must stop before merge. Do **not** use `full-send` for this repository.

This is an original project-specific adapter, not an installation of tstack. Upstream: https://github.com/t3dotgg/tstack (MIT). 
