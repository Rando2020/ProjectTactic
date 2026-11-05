# AI skills registry and adoption gates (2026-11-01)

This registry covers **project-local agent instructions proposed for ProjectTactic**. It does not certify that external CLI plugins or independent reviewer agents are installed.

| Project skill | Upstream pattern | Trigger | Output | Release gate |
| --- | --- | --- | --- | --- |
| `.agents/skills/spec-review/SKILL.md` | Google Elephant Goldfish Model, Apache-2.0 | Unclear/multi-system game feature | spec, evidence, acceptance matrix | owner design approval |
| `.agents/skills/pr-release-gate/SKILL.md` | tstack full-stop, MIT | Godot implementation / PR | draft PR, validation record | owner merge approval |

## Pilot

Use the 2.5D painterly ruined-chapel battle slice, not a React prototype:
1. Audit Godot systems and relevant open PRs; capture baseline screenshots and failures.
2. Review render/occlusion, four-direction Zane sprites, damage forecast, attack/skill/status command UI, and save stability.
3. Write an acceptance matrix: source, reproducible steps, expected behavior, status and evidence link.
4. Implement no more than one agreed slice on a topic branch.
5. Run the existing Godot checks, record what actually ran, file a draft PR and stop before merge.

## Supply-chain rules

Do not run `npx`, `curl | sh`, `git clone`, vendor code, or import external instructions blindly. Review the exact upstream commit, license, bundled scripts, dependencies and permissions before installing. Never store API tokens in skill files. Require explicit approval for deployments, release merges, purchases, and destructive changes.

## Definitions of success

- Every substantive PR links to source evidence and has a clear owner approval gate.
- Every test result is either verified with a command/log or marked unverified.
- Godot remains authoritative and working assets are preserved.
- Independent EGM review is reported only when fresh isolated agents genuinely ran.
