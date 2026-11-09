# Blooming combat UI review

This work remains on the isolated 2v2 prototype branch. It does not replace the main game, change the default title route, publish Pages, or enable new candidate art.

## Player flow

- Select a unit. The active ally offers commands; enemies and waiting allies expose read-only HP/MP inspection.
- Move, Attack, and targeted Skills show the authoritative hover forecast. Select a legal target to lock a review, then use Confirm or Enter. Repeated board clicks never commit. Esc returns to targeting without spending resources.
- Self/range-zero Skills also enter review before execution. Esc reopens the skill list with keyboard focus restored.
- Wait opens four facing choices. Choosing a direction does not rotate the unit or spend the turn. End turn applies the facing and ends the turn; Esc returns to commands.
- The same BattleManager still validates and executes all combat. Base/main-game UI behavior is unchanged except for an overridable skill-selection hook whose default delegates exactly as before.

The Blooming inspection panel is now visible instead of being hidden by its HUD adapter. Its command container measures its contents, keeping review and facing controls reachable at 960×540, 1280×720, and 1920×1080 with the tester rail open or closed.

## Verification

Godot 4.6.3. Test-driven additions observed failing on the original behavior before implementation:
- `tests/blooming_hud/CombatFlowTest.tscn`: enemy inspection, hints, staged move, repeated click safety, cursor lock, review cancellation, selection changes, real move execution, Wait/facing and real keyboard navigation.
- `tests/blooming_hud/SelfReviewTest.tscn`: real skill button, self-cast forecast, cancellation/focus recovery, MP/action charged exactly once on confirmation.
- Existing Selection, Rotation, and PortraitTurn tests now explicitly confirm their actions rather than assuming immediate execution.
- Independent code and real-input review found and verified fixes for facing navigation, stale review copy, self-cast bypass, and keyboard focus restoration.

The broad standalone sweep also includes inherited main-game tests. These three existing failures reproduce on the untouched restored baseline, before these UI changes:
- `prototypes/isometric/Test.tscn`: retired 1v1 title-route expectation (1 failure).
- `tests/test_playable_loop.tscn`: main-game practice/rig/comparison expectations in this standalone demo (4 failures, followed by an invalid freed-object script error).
- `tests/test_zane_duel_practice.tscn`: main-game duel/replay route expectations (11 failures).

Some inherited tests print shutdown resource-leak diagnostics despite passing their assertions. These are not presented as a clean whole-project run. The dedicated workflow validates the supported 2v2/Blooming UI contracts; it does not erase the broader audit findings above.

## Render evidence

Local headless checks establish logic and layout bounds, not visual approval. The `Isometric combat UI` workflow uses a real Xvfb rendering display and captures the actual Blooming scene through the same test's `--capture-dir` option. It uploads enemy inspection, move review, and Wait-facing PNGs. Inspect the generated artifact before promoting this work. Headless capture mode is deliberately rejected. Browser and physical phone interaction remain unverified.

## Source provenance

The first branch commit restores the previously saved Blooming source overlay, separately from these behavior changes. Its five terrain PNGs match the existing `demo/blooming-ruins` Git blobs exactly; no replacement art is generated or introduced here. The overlay remains opt-in through `res://prototypes/blooming/BloomingBattle.tscn`.
