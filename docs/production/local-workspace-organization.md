# Local Workspace Organization Guide

This guide explains how to safely organize a local ProjectTactic folder such as:

```txt
C:\Users\jojo3\Coding\ProjectTactic
```

The project is now Godot-first. The production game lives under `godot/`. The former React/Vite files under `src/` remain useful as reference material, but new gameplay work should not be added there.

## Golden rule

Do not mass-delete or drag-and-drop folders by hand until you have checked Git status and created an audit.

Use this order:

1. Confirm the local folder is the Git repo.
2. Pull latest `main`.
3. Create a cleanup branch.
4. Run the audit script in dry-run mode.
5. Review the reports.
6. Run the script with `-Apply` only when the move plan looks safe.
7. Commit the cleanup branch and open a PR.

## Recommended folder ownership

| Path | Use |
|---|---|
| `godot/` | Production Godot project |
| `godot/scenes/` | `.tscn` scene files |
| `godot/scripts/` | `.gd` runtime scripts |
| `godot/assets/characters/` | Unit sprites, portraits, animation sheets |
| `godot/assets/tiles/` | Terrain tiles and map-building art |
| `godot/assets/ui/` | UI frames, panels, buttons, cursors, icons used by screens |
| `godot/assets/audio/` | Sound effects |
| `godot/assets/music/` | Music tracks |
| `godot/assets/vfx/` | Spell frames, hit effects, overlays |
| `godot/assets/_inbox/` | Unsourced or unclassified assets waiting for review |
| `docs/architecture/` | System architecture docs |
| `docs/design/` | Game design, UI design, narrative design |
| `docs/systems/` | Combat, jobs, progression, save/load, run systems |
| `docs/production/` | Operational guides, local setup, build/deployment notes |
| `docs/_inbox/` | Loose notes waiting to be converted into real docs |
| `data/jobs/` | Job/class data |
| `data/story/` | Chapter, route, dialogue, story content |
| `data/towns/` | Town and hub data |
| `data/items/` | Items, equipment, consumables |
| `data/maps/` | Map definitions and battle map data |
| `tools/` | Scripts and maintenance helpers |

## Safe PowerShell workflow

From PowerShell:

```powershell
cd C:\Users\jojo3\Coding\ProjectTactic
git status --short
git fetch origin
git checkout main
git pull origin main
git checkout -b chore/local-folder-cleanup
```

Run the organizer in dry-run mode:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\organize-projecttactic-workspace.ps1
```

Review the generated reports under:

```txt
_workspace-audit\<timestamp>\
```

Important files to review:

| Report | What to check |
|---|---|
| `git-status-short.txt` | Whether local files are already modified |
| `directory-check.csv` | Missing expected folders |
| `file-inventory.csv` | Full file inventory excluding `.git`, `node_modules`, `.godot`, `dist`, and audit output |
| `large-files-over-10mb.csv` | Large assets that may need Git LFS later |
| `loose-root-file-move-plan.csv` | Root-level files the script proposes moving |

If the move plan looks safe, apply it:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\organize-projecttactic-workspace.ps1 -Apply
```

Then review the result:

```powershell
git status --short
```

## What the script does

The script is intentionally conservative.

By default, it:

- Confirms the target path exists.
- Confirms `.git` exists.
- Records current Git branch, remotes, and status.
- Creates any missing expected folders only when `-Apply` is used.
- Writes a full file inventory.
- Flags files larger than 10 MB.
- Builds a proposed move plan for loose root-level files.

When `-Apply` is used, it only moves loose root-level files that are not in the protected root file list.

## What the script does not do

It does not:

- Delete files.
- Move files from nested folders.
- Rewrite imports.
- Rename Godot resources.
- Move `.gd`, `.tscn`, `.tres`, or `.import` files automatically.
- Touch `src/`, `archive_react/`, or Godot runtime folders unless they are missing expected directories.

## Protected root files

The following root files stay where they are:

```txt
.gitignore
.gitattributes
AGENTS.md
AI_TASK_PACKETS.md
ARCHITECTURE.md
CLAUDE.md
LICENSE
README.md
SKILL.md
index.html
package.json
package-lock.json
pnpm-lock.yaml
vite.config.js
vite.config.ts
```

## File grouping rules

Loose root files are grouped by extension:

| Extension examples | Destination |
|---|---|
| `.png`, `.jpg`, `.jpeg`, `.webp`, `.gif`, `.svg` | `godot/assets/_inbox/images/` |
| `.wav`, `.mp3`, `.ogg`, `.flac` | `godot/assets/_inbox/audio/` |
| `.glb`, `.gltf`, `.fbx`, `.obj`, `.blend` | `godot/assets/_inbox/models/` |
| `.md`, `.txt`, `.docx`, `.pdf` | `docs/_inbox/` |
| `.json`, `.csv`, `.yaml`, `.yml` | `data/_inbox/` |
| `.ps1`, `.bat`, `.cmd`, `.sh` | `tools/_inbox/` |
| Other loose files | `_inbox/` |

## Best practice

Use the script to create an audit, then manually promote files out of `_inbox` folders after deciding what they are.

Examples:

| File type | Final destination after review |
|---|---|
| Original unit sprite sheet | `godot/assets/characters/` |
| Generated spell animation frames | `godot/assets/vfx/` |
| Battle panel mockup | `godot/assets/ui/` or `docs/design/` depending on whether it is used in-game |
| Story outline | `docs/design/` or `data/story/` depending on whether it is prose/reference or structured game data |
| Map concept image | `docs/design/` first, then `godot/assets/tiles/` only if production-ready |

## Pragmatic workaround

If the folder is already chaotic and you need fast stabilization, run the dry-run audit, then only apply moves for loose root assets. Leave nested folders alone until the game boots cleanly in Godot.

## Risk

Godot can rely on import metadata and resource paths. Moving production `.gd`, `.tscn`, `.tres`, `.res`, `.uid`, or `.import` files manually can break references. That is why this script avoids moving nested Godot files automatically.

## Next recommended action

Run the dry-run command locally, then share the `loose-root-file-move-plan.csv` contents or a screenshot of `git status --short` if you want help deciding what should actually move.
