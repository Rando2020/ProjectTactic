# Codex Prompt: Ingest Generated Assets

Use this prompt when asking Codex to wire generated assets into the ProjectTactic repo.

```txt
You are working in the ProjectTactic repo.

Goal:
Ingest the latest generated placeholder assets into the browser prototype and Godot demo without breaking existing gameplay.

Rules:
- Do not commit directly to main.
- Create a feature branch named feature/asset-registry-ingestion.
- Preserve existing imports and working routes.
- Do not replace gameplay systems.
- Use lowercase kebab-case filenames.
- Keep browser assets under src/assets/.
- Keep Godot assets under godot/assets/.
- Add or update documentation when adding a new asset system.

Tasks:
1. Inspect the existing repo structure.
2. Create these folders if they do not exist:
   - src/assets/tiles/
   - src/assets/characters/
   - src/assets/ui/
   - src/assets/vfx/
   - src/assets/icons/
   - godot/assets/tiles/
   - godot/assets/characters/
   - godot/assets/ui/
   - godot/assets/vfx/
   - godot/assets/icons/
3. Add generated asset files into the correct folders.
4. Create src/assets/assetRegistry.js.
5. Create godot/scripts/data/AssetRegistry.gd.
6. Map gameplay IDs to asset paths for:
   - grass tile
   - road tile
   - stone tile
   - water tile
   - move highlight
   - attack highlight
   - ability highlight
   - Zane idle and portrait
   - Mira idle and portrait
   - Kael idle and portrait
   - Null Drake idle
   - Storm Imp idle
   - Fen Wraith idle
   - command icons
   - elemental VFX placeholders
7. Update tactical grid and UI components to use registry references where safe.
8. If a direct gameplay integration risks breaking the build, add the registry and docs only, then leave TODO comments for integration.
9. Run the project build or available validation command.
10. Open a PR into main.

Acceptance criteria:
- No assets are committed to root-level folders.
- Registry files exist and are documented.
- Existing game screens still load.
- Build passes or the exact failing command and error are documented in the PR.
- PR summary lists files added, files modified, risks, and follow-up tasks.
```

## Notes for Codex

The first objective is organization, not final art. Do not over-engineer animation playback yet. Use simple registry mappings first, then wire sprites into battle screens after file paths stabilize.
