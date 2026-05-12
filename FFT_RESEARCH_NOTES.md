# Final Fantasy Tactics Reverse-Engineering Notes (Legal/Safe Approach)

## Can we look at FFT internals online?
Yes — there is community documentation about data tables, routines, and file layout for the original PS1 release.

Important: use this for **design inspiration and architecture learning**, not copying copyrighted game assets/code.

## What is documented publicly
- `SCUS_942.21` routines and data tables (main executable mappings).
- `BATTLE.BIN` table references (battle-specific systems).
- RAM/file offset maps for where tables are loaded.
- Community tooling and assembly notes for modding/hacking.

## What we can borrow (ideas), safely
- Turn architecture concepts (CT-like timeline, move/act/facing phases).
- Tile math patterns (height deltas, movement costs, jump checks).
- Data-driven tables for jobs, abilities, status, and AI behavior.
- Content pipeline patterns (separate battle/world data modules).

## What we should NOT copy
- Original sprites, audio, text scripts, map files, proprietary binaries.
- Decompiled code content directly into this repository.

## How to use this for ProjectTactic (recommended)
1. Keep all assets original or from explicitly licensed sources.
2. Implement mechanics in your own code/data schema.
3. Build your own map/ability/status formats inspired by SRPG best practices.
4. Keep citations for every external reference and license in docs.

## Starter references
- Final Fantasy Hacktics Wiki (SCUS tables):
  - https://ffhacktics.com/wiki/SCUS_942.21_Data_Tables
  - https://ffhacktics.com/wiki/SCUS_942.21_Routines
- FFT/PSX table locations:
  - https://cheetah.ffhacktics.com/wiki/FFT/PSX/Data/Table_Locations
- BATTLE.BIN data table references:
  - https://forum.ffhacktics.com/wiki/BATTLE.BIN_Data_Tables
- Translation file catalog notes:
  - https://gomtuu.org/fft/trans/catalogs/

## Next engineering step in this repo
- Add a CT timeline simulation module and connect it to the existing tactics prototype phases.
