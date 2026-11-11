# Courtyard skill audio

`CourtyardSkillAudio.gd` generates original deterministic PCM sound effects at runtime. These are synthesized cues, not licensed studio recordings. No assets are downloaded, no random/global combat state is used, and Fire's existing `ModularSpellAudio.play(kind, owner)` path is unchanged.

## Integration

Preload `res://scripts/presentation/CourtyardSkillAudio.gd` and call:

```gdscript
var voice = SkillAudio.play(ability_id, phase, presentation_owner)
```

Ability IDs: `haste`, `defend`, `thunderstrike`, `void_pulse`, `dark_breath`, `shadow_mend`, `mighty_strike`, `delay_strike`, `heavy_slash`. Display names such as `Mighty Strike` also work. Phases: `charge` (0.34 s Mighty Strike, 0.28 s Delay Strike, 0.46 s Heavy Slash, otherwise 0.60 s), `release` (0.20 s), `contact` (0.28 s), `heal` (0.42 s). Use the appropriate phase once at the authored animation event; this helper does not schedule gameplay or animations. Unknown skills/phases, including Fire, return null instead of an incorrect generic cue.

Returned `AudioStreamPlayer` nodes are children of the supplied presentation owner. Retain each voice in the presenter's cancellation list. Stop and free it when cancelling a phase; freeing the owner also frees its voices. Natural completion queues the voice for deletion. Detached, null, and queued-for-deletion owners are rejected. No timers or delayed playback callbacks survive cancellation.

The helper routes to the existing `FX` bus without changing its volume or mute state. PCM peaks are normalized to 0.70 and each player runs at -12 dB (maximum effective single-voice peak about -15.1 dBFS). This leaves headroom for overlapping phase tails, but callers must still avoid duplicate event dispatch. Streams are cached by the bounded set of 36 skill/phase pairs.

## Sound identities

- Haste: ascending bright chirps with airy shimmer.
- Defend: rounded bronze-shield resonance.
- Thunderstrike: electrical buzz/crackle and descending thunder.
- Void Pulse: low, hollow beating tones.
- Dark Breath: rough breath texture with wavering bass.
- Shadow Mend: soft chord and restorative chime.
- Mighty Strike: heavy low drum with impact transient.
- Delay Strike: clock-like ticks and descending ring.
- Heavy Slash: noisy blade sweep with metallic edge.

Each phase changes pitch, duration, and envelope while retaining the ability's timbre. Envelopes begin and end at zero to avoid discontinuity clicks.

## Verification

Run from this demo directory with Godot 4.6:

```sh
godot --headless --path . --script res://tests/modular/test_skill_audio.gd
godot --headless --path . res://tests/modular/test_audio.tscn
```

The focused test exercises real generated PCM, 36 distinct skill/phase waveforms, deterministic repeats, duration, RMS level, peak headroom, click-free endpoints, unchanged FX mute, returned-voice cancellation, natural cleanup, owner cleanup, and invalid-input rejection. It does not claim a listening review or browser-audio validation.
