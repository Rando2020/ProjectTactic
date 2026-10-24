# Combat choreography verification

## Implemented

- Existing sprite art, terrain, music and procedural impacts reused.
- Awaited anticipation, sprite-only lunge, arrow travel and casting orb.
- Contact-aligned physical feedback; synchronous spell outcomes fix the unawaited spell resolver delay.
- Player commands gated during anticipation and recovery; automation awaits the same action handlers.
- Heal particles render visible crosses; heal numbers report actual restored HP.
- VFX uses the battlefield foot projection, including terrain elevation.

## Evidence

- Initial gameplay regression: 43 checks passed.
- Final gameplay regression: 49 checks passed, including input lock/recovery, immediate spell outcomes, no delayed duplicate damage and actual restored-HP feedback.
- Godot Web release export succeeded.
- Packaged WASM validity, PCK header, reconstructed byte lengths, subpath requests and native fetch passthrough checks passed.
- Private Site versions 1 and 2 deployed successfully; version 2 contains the final 49-check build at https://appointed-tactics.zzziah.chatgpt.site.
- Managed browser opened the actual export at http://terminal.local:4173/ and reported missing WebGL2 and Secure Context. No gameplay frames, frame-rate measurement, visual acceptance or human balance claims are supported by this browser result.
- Two pre-existing resources-in-use warnings persist at headless shutdown. Runtime script errors are test failures.

## Controls and acceptance route

Play / Visit the Hearth, Begin Descent, choose a battle and deploy. M selects movement, A attack, S ability, W wait. Hover to inspect forecasts, then click a legal target. Move and act once in either order. Cancel exits targeting. Continue restores the encounter checkpoint, not an individual turn.

Inspect a melee strike, arrow, offensive spell, area spell, Cure and Protect. Complete a battle, collect rewards, choose the next route, reload, then Continue. Observe defeat and return to the Hearth separately; direct encounter retry is not yet implemented.

See `docs/production/combat-asset-inventory.md` for the asset audit and explicit remaining scope.
