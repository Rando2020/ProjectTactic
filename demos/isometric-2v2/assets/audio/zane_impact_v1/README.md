# Zane impact v1 — original cue pack

Ten original, deterministic, locally authored effects for Zane's movement,
sword and canonical Fire. No external samples, recordings, model output,
commercial services, existing combat WAVs, or third-party sound libraries are
used. Everything audible is synthesized from the code in
`tools/generate_zane_impact_audio.py`; the Python standard library is the only
build dependency. This is authored sound design, not a claim of recorded boots,
leather, steel, or flame. No physical field-recorded sources are present.

## Provenance and reproduction

Author: ProjectTactic / Codex, 2026-10-24, specifically for the approved Zane
impact slice. The generator itself is the complete editable source; no hidden
DAW project, preset, external asset, or download is required. The source's
explicit xorshift32 per-cue seeds, filter equations, envelopes, mode frequencies
and layer balances specify the recipe. Python 3.12 on Linux produced this pack.
Double-precision `math` is used; exact byte equality is tested in this build
environment, not claimed for every libm/platform implementation.

From the repository root:

```sh
python3 tools/generate_zane_impact_audio.py
python3 -m unittest tools.test_zane_impact_audio -v
# Optional review artifacts; do not commit these previews:
python3 tools/generate_zane_impact_audio.py --preview-dir /tmp/zane-impact-audition
```

`manifest.json` records SHA-256 of the actual RIFF/WAV bytes and exact sample
count-derived duration for each source. Regenerating replaces only these ten
WAVs and their manifest, and does not rewrite this authored provenance.

All WAVs are 48 kHz, mono, PCM16 little-endian, with no loop/metadata chunks.
Source peaks are -4.5 to -5.8 dBFS (at least 1.5 dB beyond the required -3 dBFS
headroom). Cues have 12 ms cosine attack safety and 20 ms tail fade, DC correction,
and gentle pre-normalization saturation. They are not loudness-normalized to
commercial music. Runtime `gain_db` is deliberately additional attenuation,
not baked in. Keep the specified FX → Game bus routing and mute behavior.

## Layer intent

- **step_a / step_b:** two independent seeded boot plants: short heel/body
  cavity, delayed sole friction, irregular fine grit and lower leather rub.
  Their timing, body tuning and noise differ; neither is a relabelled sample.
- **sword_load:** uneven cloth friction with quiet inharmonic steel tension.
- **sword_release:** fast broad air shear and a lower body/fabric wake; no
  pitched whistle or oscillator-only beep.
- **sword_hit:** low-mid resistance/body, a short nonmusical metal edge and
  tiny uneven surface contacts, not a long ringing sword chime.
- **fire_charge:** rising noisy pressure and tiny ember contacts around two
  bent cavity modes. The body supports the noise rather than forming a tune.
- **fire_release:** rounded breath/pressure bloom, ignition scrape and ember
  grains; no instantaneous firearm-style impulse or sampled explosion.
- **fire_hit:** low-mid resistive body and warm flare/crack, resolving into a
  sparse soft ember/air tail. It is an action-level master impact.
- **fire_miss:** airy thinning heat with no resistive impact body.
- **fire_immune:** small brittle deflection plus air, intentionally restrained
  relative to actual HP/armor contact; not a damage explosion.

All textures use deterministic filtered bipolar noise, sparse windowed noise
grains and short inharmonic damped modes. References above describe physical
analogues, not sampled sources. No global combat random state is consulted.

## Review previews and acceptance limits

`--preview-dir` writes two **source-only**, review-only WAVs and a timing
sidecar outside the runtime pack. `cue-audition.wav` presents all ten cues at
source unity gain separated by silence; its order/times are in
`preview-events.json`. `fire-sequence.wav` applies the manifest gains to charge
at 0.30 s, release at 0.50 s, then one master impact at 0.72 s (0.22 s travel).
It represents three hypothetical recipients without tripling release or hit.
It is not evidence of runtime timing, bus/mute operation, cancellation, or
actual gameplay integration. Runtime must choose only one outcome tail and
at most three new voices, independently of this pack build.

Automated format, level, DC, endpoint, duration, hash, pack-size, uniqueness and
reproduction tests are not an audition or a perceptual quality certificate.
Physical speaker/headphone checks are **unverified** unless a real listener
performs them. The implementation report records available decoded-channel
listening status separately; listening must not be inferred from tests or
waveform inspection.

These ten reviewed WAVs are stored as raw Git blobs under the narrow
`godot/assets/audio/zane_impact_v1/*.wav` attributes exception. Other WAVs
retain their existing LFS policy. Remote publication and clean-checkout
verification remain separate gates; neither is established by a local build.
