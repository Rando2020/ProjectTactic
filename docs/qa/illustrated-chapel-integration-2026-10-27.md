# Illustrated chapel integration candidate

## Scope and provenance

Local feature branch `feature/illustrated-chapel-polish` combines the unmerged source of PR #84 (`7e563047`), #83 (`0a831815`), and #82 (`94f87310`). Main, the public demo, saves and original 3D assets are unchanged. No artistic fidelity acceptance is implied.

The approved standalone portrait crop is copied byte-for-byte from `projecttactic-zane-illustrated-2-5d-reference-kit.zip`, `portraits/zane-portrait-illustrated-source.png` to `godot/assets/characters/portraits/zane-portrait-illustrated.png`.
SHA-256: `89b6de0b4039de9b509aa475252caa9ab0f7102104f84ba202c7ce26f9349c2e`.
This is a 199 x 372 concept-derived crop suitable for small portrait slots, not a high-resolution 4K character master. Rejected sprite masks and the complete concept collage are not runtime assets.

## Integration repairs

- Source image decoding is restricted to PNG/JPEG. SVG chapel assets use their imported Texture2D, avoiding erroneous PNG decoding and corruption diagnostics.
- Forecast, active identity and CharacterScreen retain the portrait architecture from #83. Accepted-action and counter banners now resolve that same manifest-backed illustration instead of the older UnitData art.
- The action-banner test is a scene so Godot initializes GameState before compiling BattleManager. The standalone-script version failed and timed out.
- Damage-label placement reserves the banner card, not its transparent full-screen wrapper. The original integrated impact suite reproduced 104 failures; after the repair it reports 1,452 checks and zero failures.
- Portrait export now emits lossless PNG matching the manifest. The sprite-export positive fixture was only 30 pixels wide despite the existing 32-pixel minimum. It now uses a valid 40-pixel silhouette, with a separate negative test preserving rejection of the 30-pixel case.
- CI runs the portrait/export contracts, which were not registered in #83.

## Visual comparison with the approved target

| Target | Candidate status |
| --- | --- |
| Painterly Zane portrait | Actual approved crop integrated; large status/4K quality unaccepted |
| Four clean directional illustrated units | Missing; existing sprite fallbacks preserved |
| Painted raised stone and ruined chapel | Existing #84 SVG approximation; no claim of matching painted texture quality |
| Dark forecast with controlled Fire accent | Existing forecast preserved; no full-screen tint added |
| Compact action ribbons | Integrated; geometry checked at 1280/1366/1600/3840 widths and 100/125/150% factors |
| Actual browser encounter screenshots | Blocked before title screen by environment requirements |

## Browser limitation

The exported Godot Web build was served through the managed preview at `http://terminal.local:4173/`. The real cloud browser displayed both missing requirements: WebGL2 and Secure Context (HTTPS). Local Chromium also could not start because the executor denies its process-singleton socket. No browser security settings or game requirements were bypassed.

The evidence capture is an error screen, not gameplay. Mouse/keyboard interactions, rendered 1280/1366/1600/4K layouts, accessibility scaling, visual animation cleanup, KO/retry and refresh/Continue are **not browser-validated**. Headless checks do not substitute for those observations.

## Next acceptance gate

Run this branch export in a WebGL2-capable browser through localhost or an approved separate HTTPS preview. Choose **Illustrated Chapel / Play 2.5D Battle**. Capture idle, movement, Fire forecast, impact, status and retry at the requested sizes before terrain or sprite refinement. No merge or live deployment is requested by this document.
