# Zane Fire: same-frame imported hand following

## Root cause and bounded change

The exact PR77 tree `99f45eae384829ec1ab43d60838a86771bb91d30` failed the
full-party Chrome Fire gate: charge samples at frames 113/114 missed the
same-frame hand by 26.92369/8.06354 px. Frame 114's charge exactly matched
frame 113's hand. The action itself resolved correctly.

This was reproducible in production node geometry, not repaired by changing
what the QA observer accepts:

1. `/root/VFX` is an earlier autoload subtree than the battle's units.
2. At the former common priority 0, `ZaneActionPresentation._process` copied
   the previous pose's projected socket into the charge.
3. The later `ZaneImpactRigPresentation._process` called the shared manual
   animation sampler with this frame's delta. `AnimationPlayer.seek/advance(0)`
   and explicit skeleton/attachment synchronization updated the imported hand.
4. A read-only observer after both trees still saw the stale charge and new
   hand. A diagnostic frame reproduced a 26.55771 px mismatch at process end;
   the next owner update copied exactly that preceding hand position.

Only the approved Zane adapter now uses `process_priority = -1`. Its existing
manual pose/bone update therefore precedes default-priority VFX following.
The shared base adapter, owner, clocks, animation samples/durations, camera,
foot anchor, display footprint, models, gameplay and RNG are unchanged.
Both approved impact and painterly profiles use this adapter. No observer
comparison, historical hand substitution, browser flag or threshold changes.

A matching diagnostic after the change showed a 26.54005 px transient gap
*before* the follower, then exactly 0 px after the follower and at process end.
This confirms that the update order changed, rather than the observation
being moved to conceal the gap.

## Regression contract

`test_zane_impact_actions.gd` includes `fire_socket_frame_contract` in its
normal suite and exposes a focused `--socket-frame-probe`:

```sh
data="$(mktemp -d)"
XDG_DATA_HOME="$data" XDG_CONFIG_HOME="$data" XDG_CACHE_HOME="$data" \
  godot --headless --path godot res://tests/test_zane_impact_actions.tscn \
  -- --socket-frame-probe
```

It admits the real Fire action and observes the real imported hand and owned
charge at end of node processing. The test-only observer never forces bone
updates or manually advances animation. Its moving case introduces 75 ms of
main-thread workload; the subsequent engine frame uses the actual elapsed
delta. A separate deliberately frozen-pose control detects unrelated
projection/observation errors. The test retains per-frame geometry and checks:

- Multiple actual charge frames and the first real projectile frame exist.
- **Every** retained charge is within the unchanged 8 px same-frame tolerance;
  first launch is within the unchanged 16 px tolerance.
- The moving hand travels more than 8 px and includes a real >=50 ms frame;
  the control hand remains stationary.
- Camera, foot, output size/position, time scale, one resource spend and one
  authoritative resolver result remain intact; original disposal checks run.

Before production changes, the regression failed only the moving alignment
check (21.13061 px maximum, 26.48913 px hand travel, 83.176 ms frame). The
stationary control was 0 px. After the scheduling change: 0 px maximum
charge error, 26.59635 px hand travel, 82.048 ms frame, 4.20603 px launch error;
19 checks, zero failures. Values are measured samples, not new tolerances.

## Local verification

- `python tools/check_playable_loop.py`: all 31 native contracts passed,
  including impact actions 1452/0, impact rig 120/0, full-party showcase 84/0,
  duel practice 179/0 and actual painterly rig 289/0.
- `python -m unittest discover -s tools`: 152 tests passed.
- `node --test tools/test_web_package.mjs`: 35 tests passed.
- `export_browser_qa.py --validate-only` for `zane-showcase` and `zane-duel`:
  original observer, showcase observer, and normal/slow-tail/slow-frame duel
  observer contracts passed. Staging was removed and project configuration
  restored exactly. This was native validation, not a new Web export/run.

The native aggregate retains its pre-existing, explicitly allowlisted
ObjectDB/resource shutdown diagnostics in spell-outcome feedback (2),
cancel-move input (1), scout-outcome integration (1), resource HUD (1) and
playable-loop (3). No new Zane fixture errors or warnings were reported;
these legacy diagnostics were not hidden or newly waived.

## Evidence boundary and remaining browser acceptance

Native headless Godot 4.6.3 uses the dummy renderer. The fixture subscribes to
real `RenderingServer.frame_pre_draw` / `frame_post_draw` signals and labels
them independently, but both callback counts were **zero** in these runs.
Its process samples are **geometry**, not rendered-pixel or hardware evidence.
The retained earlier Chrome `failure.png` is a later cleanup frame, not
charge pixels. No visual acceptance claim follows from these native tests.

The exact changed head must still run existing real Chrome Quickstep,
full-party Fire and painterly duel gates. The 8/16 px Fire assertions remain
unchanged. Short-lived charge-frame pixel capture remains unverified; no
new capture infrastructure is part of this fix.
