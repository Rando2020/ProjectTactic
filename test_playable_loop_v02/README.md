# The Appointed - Playable Loop v0.2 Test Folder

This folder is a safe staging area for the next playable cleanup pass.

Nothing here is meant to delete or replace live game files yet. Use it to:

- snapshot the current Godot loop files before cleanup,
- name the static UI/UX assets we want before character-heavy work,
- keep Midjourney replacement filenames stable,
- decide which live Godot files to patch once the direction feels right.

## Current Scope

Playable Loop v0.2 is about making the game fun to test with static and placeholder art.

Target flow:

Antechamber -> run setup -> route choice -> deployment -> battle -> spoils -> boon/town choice -> next floor -> results

## Do First

1. Keep runs short for testing: 8 to 10 floors.
2. Make manual play the default; auto-battle stays as a debug toggle.
3. Make battle decisions readable before adding new character art.
4. Add visible feedback for enemy intent, damage forecast, terrain, rewards, and carryover HP.
5. Name every static asset cleanly so replacement art can drop in later.

## Folder Map

- `code-snapshots/` - copies of the main Godot loop files as they existed before this cleanup.
- `static-ui-placeholder-manifest.csv` - stable filenames and usage notes for static assets.
- `static-ui-ux-polish-list.md` - prioritized UI/UX work list.
- `midjourney-batch-prompts.md` - reusable prompts grouped by asset family.
- `live-cleanup-targets.md` - recommended live code changes once we patch the actual game.

## Rule

Character sprites with four directions are intentionally out of scope for this pass.
