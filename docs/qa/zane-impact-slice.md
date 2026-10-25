# Zane impact slice: evidence and release boundaries

This is the first playable presentation pass for Zane's movement, sword attack,
and existing Fire skill. It is not a finished character-art or audio-mix approval.
The released comparison baseline is `29cead4dca4e6dbafa123bc002c230d81d66a403`.

## Preserved gameplay

- Fire remains the canonical `fire` ability (`fireball` alias): 12 MP, range 3,
  power 100, three-tile perpendicular fan, and the existing burn rules.
- No new skill, forced hit, changed initiative, party replacement, resource refund,
  status application path, counter/death path, or persistent preference is added.
- `Practice: Zane showcase` starts the normal practice party and initiative.
  Movement, sword, and Fire can be tried on separate turns. Reduced motion is
  session-only; existing sprite/original-rig fallbacks remain available.
- Presentation cancellation cannot grant early contact. Cancellation after contact
  does not undo authoritative damage, costs, or turn progression.

## Asset and sound provenance

Original shared-rig source was retained. The variant changes only walk, slash,
and cast, preserving the sixteen-bone rig, rest/bind data, three sockets, nine
clip names/durations, and six untouched clips. The reviewed GLB SHA-256 is
`669244b98a1ba99dde3996b3b4834fb142081fe5d1661e5f2be5e748529e4a90`.

Blender 4.3.2 rebuilt the variant byte-for-byte. Dense export validation sampled
1,277 poses without tested blade/body crossings outside the intentional grip;
minimum tested floor clearance was 0.00532244 world units. These tests do not
establish complete self-collision, cloth physics, inverse kinematics, or foot-lock.

Ten original synthesized mono 48 kHz PCM16 WAVs total 225,464 bytes. Deterministic
reproduction and format/level/DC/endpoint/duration checks passed. These are draft
sounds: waveform checks and cue events are not a listening or mix-quality test.

The thirteen new GLB/Blend/WAV artifacts are self-contained raw Git blobs through
narrow attributes exceptions. Existing asset paths and LFS policies are unchanged.
A fresh remote checkout must still be checked at release; local blob availability
is not remote delivery evidence.

## Independent checks completed before final release

- Rig adapter: 120 checks, including 126 malformed metadata variants without
  engine script errors; canonical cardinal facing and original fallback retained.
- Action controller: reviewed cancellation/lead-in gating, truthful applied HP and
  armor outcomes, real death cleanup, one ticket owner, bounded cues/effects, and
  unchanged gameplay/RNG authority. Original action suite passed 404 checks before
  the later readability-test additions.
- Showcase controls: 84 checks each with default, saved FX=0, and saved FX=61.
  External comparisons confirmed preference-file bytes and existence unchanged.
- Outcome readability: actual overlapping native labels reproduced, then repaired
  with measured swept bounds. A second independent test caught unscaled header
  anchors; corrected real Unit/global Control bounds passed 1,021 checks. Pure
  placement matrix passed 60,486 checks across viewport sizes, UI modes, zoom,
  orientations, long labels, and visible HUD obstacles.
- Optional browser QA: default Quickstep unchanged. An independent false-pass
  finding was fixed with exact full-label consumption and multiplicity per
  recipient. Eighteen focused tests and seventeen independent adversarial cases
  passed. Actual misses/immunity remain valid outcomes, not forced hit coverage.
- Release wiring: separate production/default/Zane exports and package checks,
  post-staging production exclusion, original Quickstep path, failure propagation,
  and mandatory screenshot/report retention were independently reviewed. The
  registry contains 28 contracts: 25 scenes and 3 scripts. Only the frozen 24
  legacy cases retain their exact documented shutdown-resource exception.

## Actual native observations

Godot 4.6.3 Compatibility rendered the game in a 1328×861 native window on cloud
software rendering (Mesa llvmpipe), not a hardware-GPU or 4K performance test.
Normal inputs moved Zane, then cast Fire on a later turn: MP 90→78 once; Storm Imp
lost 44 HP/17 Ether, Void Cultist lost 33 HP/13 Ether with RESIST, both received
Burn, and Null Drake was untouched. A later sword attack applied 40 remaining HP
and 18 Temper, then the target faded/retired; MP stayed 78. Transient effects
cleaned up and an idle sprite/3D toggle restored the rig.

These observations were on the pre-readability-fix build, and exposed the overlap
that motivated the repair. Corrected native pixels and final exported-browser
acceptance are separate release gates, not inferred from these older captures.
Screenshots are sparse observations, not validated frame-time measurements.

## Remaining acceptance and known limits

- Final combined contract/export results and exact published commit must be
  recorded in the release/PR evidence. Component results above are not substitutes.
- Actual Chrome/WebGL input, screenshots, and inspected pixels are required for
  the optional scenario. See [browser-zane-showcase.md](browser-zane-showcase.md).
- The native audio backend fell back to a dummy driver. No physical audition,
  headphone balance, subjective impact quality, or browser audible output is
  claimed. User listening feedback remains necessary.
- Native 4K rendering, hardware-GPU performance, full four-facing/elevation action
  visuals, and a complete campaign playthrough are not established by headless
  geometry or this scoped native encounter.
- A pre-existing fixed-delay test observation could fire before the presentation's
  real lead-in elapsed because a newly created SceneTreeTimer consumed an older
  frame delta. The test-only repair now observes real release with a two-second monotonic
  bound while retaining both original flight assertions. A controlled 300ms-frame
  regression failed before the repair and passed afterward; an independent
  exact-commit probe passed 7 checks with clean diagnostics. Production timing
  was not changed and no failures were waived.
- Original aggregate shutdown/resource diagnostics remain disclosed and narrowly
  classified; the new Zane cases do not inherit a broad warning/error exemption.
  Static production diagnostics remain the original nineteen warnings.

No new paid service, external asset license, access expansion, or generation
provider is required by this slice. Publishing must preserve the existing demo's
access policy and verify its source/build identity rather than rely on an old tab.
