# Readable UI Implementation Plan

> Execute inline using executing-plans; parent owns independent review.

**Goal:** Make the existing Appointed kit readable and user-adjustable without changing world quality, combat or saves.
**Architecture:** A UI-only preferences helper stores Auto / Standard / Large / Extra large separately from audio and game saves. It reapplies typography idempotently to existing controls and exposes one keyboard-accessible selector. BattleHudLayout reserves the actual enlarged rail width; anchored/scrollable surfaces retain access at small sizes.
**Tech Stack:** Existing Godot 4.6.3, GDScript, existing SVGs/theme only.
**Spec:** Explicit user direction: bigger readable text at 4K, full design/implementation discretion; demo-delivery-contract.md retains 1366×768 accessibility.

## Constraints and rulings
- No engine/dependency upgrade, combat/state edits, private notes changes, remote publication or merge.
- Retain High/Standard world rendering independently.
- Auto prefers 125% at 1080p logical size and 150% at native 4K; clamp by available logical width. Base body text minimum 16px before the accessibility multiplier.
- Preference applies to battle, practice controls, title and results; transient battle labels get the same typography policy.
- Graphical acceptance remains pending unless actual rendering is available. Real scene rectangles and minimum sizes are testable headlessly.

## Review focus
Small window clamping; 4K with canvas stretch; long dynamic unit/ability labels; keyboard access to scrolled controls; settings must not alter game saves or graphics preference.

## Task 1 — policy and responsive rail
Files: UISettings.gd (new), AppointedTheme.gd, BattleHudLayout.gd; test_ui_readability.gd (new), test_battle_hud_layout.gd.
- [x] Write/run failing tests for preference roundtrip/clamping, larger default and small-screen bounds.
- [x] Implement preference helper, idempotent font/icon sizing and responsive rail geometry.
- [x] Run focused tests.

## Task 2 — integrate existing screens
Files: BattleUI.gd, PracticeComparison.gd, StartScreen.gd, ResultsScreen.gd.
- [x] Add real scene tests for selectors, larger fonts, rail containment, scroll/focus and modal placement; observe failure.
- [x] Apply helper after existing builders, subscribe to preference changes, keep dynamic text wrapped, center settings, place forecast within rail so it cannot cover tile interaction.
- [x] Run focused and full playable-loop checks plus all script/test checks.
- [x] Record evidence and limitations; commit only owned files and request parent review.

## Verification record (2026-10-24)
- Policy first failed for missing UISettings/wider rail; scene tests then failed for tiny fonts, no selector, non-focus-following scroll and overlay forecast. Geometry reproduction found long forecast names expanding the rail offscreen; wrapping fixed it.
- `python3 tools/check_ui_readability.py`: 1,687 checks, 0 failures, clean output. Isolated settings/save directories. Actual instantiated HUD, title, results and practice scene; 1280×720, 1366×768, 1920×1080, 3840×2160 with four modes. Includes malformed mode/persisted-value fallback, persistence roundtrip, idempotent resizing, command text fit, icons, keyboard focus with full ability button scroll-into-view, bottom loadout anchoring and practice-state independence.
- `test_battle_hud_layout.gd`: 30 assertions; `validate_all_scripts.gd`: 62 scripts.
- Full `tools/check_playable_loop.py`: 415 checks, 0 failures; baseline missing generated run-node PNGs (battle/boss/elite/wanderer) produce resource errors and inherited two-resource/ObjectDB shutdown warning. No script errors. These are outside this UI-only change.
- Other suites: element resolver 9/9, vows 23/23, Orren 31 assertions (inherited ObjectDB warning), asset manifest 94 assertions, Python recurrence/art contracts pass.
- Baseline combat formula test remains 9 pass / 1 fail: temper expected 46, got 45. Separate combat worker owns repair.
- Hydrated 222 LFS pointer assets from sibling exact-source checkout only after SHA256 verification; no assets committed. Imported files/UIDs unrelated to this task left unstaged.
- Native graphical reviewer is available separately; these geometry checks are not visual acceptance. No screenshot/performance/player-acceptance claim; no publication.

## Rulings
- Clamp requested sizes to 100% below 1600 logical pixels rather than shrinking below the new readable base. Preserve preference for larger windows. Cost: large choices converge on compact displays, explained by selector tooltip.
- Forecast moves into reserved rail rather than scaling its fixed battlefield overlay. Cost: vertical scrolling in dense states; battlefield input is unobscured and keyboard focus scrolls to controls.
- Parent owns independent final review and native graphical follow-up; no subagents or publication by this worker.

## Native observation repair (2026-10-24)
Actual native 1328×861 practice screenshot showed five turn cards breaking names into 2–3 letter stacks. Root cause: each original 62px card lost 32px to theme padding; bounds-only tests did not check shaped text. Regression populated Zane, Storm Imp, Void Cultist, Kael and Mira at five viewport sizes/four modes: 100 failures before repair. Two-column numbered grid preserves reading order and full readable names, with gold border for next projected turn (not mislabeled current turn); stable duplicate-name suffixes and full identity tooltips distinguish enemies. Existing active-unit panel remains current-turn identity. No font reduction.
Updated focused suite: 2,175 checks, 0 failures. Native tester also confirmed settings size changes visually and scrollable abilities; separate observed Long Shot→Cancel→Move behavior is assigned outside this UI worker.
Manual native-only 4K fixture in tests/manual_ui_4k_capture.tscn renders actual BattleUI in 3840×2160 SubViewport with representative data, saves PNG after frame_post_draw, and does not write game state. Its output is a UI raster fixture, not gameplay or visual acceptance.

Native reviewer additionally observed readable MOVE forecast inside rail, wheel-scrolling to actions/log, and fully contained150% settings modal. Repair source still requires native queue recheck.

## Independent review repair: populated loadout anchoring
Reviewer reproduced a real regression: after readable-font growth, the populated Vow/Sigil panel used its previous height to calculate its bottom position; actual Vow of Ignareth text then settled below the window edge. Prior empty/practice-only anchoring coverage missed this.
Added actual RunState regression cases with default vow/sigil and eight real boons, each button's real mouse-entered description, four viewport sizes and Auto/150%/100% transitions. RED: 60 failures. A dedicated position-only callback on panel.resized now reanchors after container layout settles; normal viewport layout also calls it. Hover does not reapply typography or refit the camera.
GREEN: `python3 tools/check_ui_readability.py` reports 2,465 checks, 0 failures and clean output. Full playable loop reports 415 checks, 0 failures, with the same four missing run-node PNG errors; this run reports three shutdown resources in use (earlier runs reported two), not a clean-shutdown claim. Production script validation loads 62 scripts. No input/cancel behavior changed.
Configured standard repository-local Git LFS clean/smudge/process filters without hooks/network. SHA256 of sampled hydrated asset matches its committed LFS oid; tracked index entries verified byte-identical before/after configuration. No assets or import files staged.
