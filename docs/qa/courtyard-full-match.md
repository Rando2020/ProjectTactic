# Courtyard full-encounter regression

`demos/isometric-2v2/tests/blooming_hud/FullMatchTest.tscn` plays the existing
Blooming encounter through its selection, target review and explicit Confirm
controls, then exercises the real Replay button and a fresh confirmed move.

It supplements the current release smoke, which covers real browser movement
and settings but not a full fight. This new check is **native, headless controller
coverage**, not real keyboard/mouse input, browser acceptance, graphical review,
performance measurement or a guarantee that every player strategy wins.

## What it protects

- Existing full-resource roster and original positions, including armor/statuses.
- Legal movement by both allies through the actual highlighted move range.
- Spell review and cancellation without changing positions, facing, HP, MP,
  temper, ether, statuses, or move/action availability.
- Confirmed Fire with exactly one twelve-MP spend, plus ordinary combat actions.
- Enemy initiative and real enemy AI combat outcomes.
- Victory only after both enemies are defeated through normal combat.
- Real Replay pressed twice creates only one replacement courtyard battle.
- Full roster/resources are restored and a new confirmed move succeeds afterward.
- A nonempty saved-file sentinel remains byte-identical throughout practice.

The command-selection policy reads current ranges and uses the courtyard's
existing reachable-tile helper to approach a living enemy. It does not enable
auto-battle, assign combat stats, force turns, inject damage, or trigger victory.
All actual moves and attacks still go through selection/review/confirmation.

## Run

Use Godot 4.6.3. Use isolated writable user directories so the test never loads
or writes your usual save/configuration. From the repository root:

```sh
qa_home="$(mktemp -d)"
mkdir -p "$qa_home/data" "$qa_home/config" "$qa_home/cache"
XDG_DATA_HOME="$qa_home/data" \
XDG_CONFIG_HOME="$qa_home/config" \
XDG_CACHE_HOME="$qa_home/cache" \
  timeout 180 godot --headless --path demos/isometric-2v2 \
  res://tests/blooming_hud/FullMatchTest.tscn -- --seed=20261109
```

The log prints observed turns, movement, resolved actions, defeated enemies and
replay count, followed by `Courtyard full match: N checks, 0 failures` on success.
Any failed assertion returns a nonzero process status. Test three representative
random seeds with `20261109`, `17` and `42`; do not treat these as exhaustive balance
coverage. Seeds are applied when the initial encounter is ready for input, after
practice initialization.

The existing Courtyard Web release gate already discovers every scene under
`tests/blooming_hud/*.tscn` and rejects nonzero exits, script errors and `FAIL:`
lines. No workflow change or production instrumentation is needed.

## Scope and failure verification

This change adds only the regression scene/script and this document. It does not
change runtime code, source artwork, combat balance, save formats, release
workflows, the default entry point, or deployment configuration. It is based on
the tested release candidate from PR #116 and does not merge or approve it.

A local mutation changed the actual Replay destination from Blooming to the old
Skirmish scene. The new test failed specifically on the missing Blooming
transition; the original production file was then restored byte-for-byte.
Independent review checked the actual APIs and assertions, and the resulting
snapshot coverage includes all StatusEffect values rather than Resource identity.
